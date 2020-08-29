defmodule Wumpex.GatewayTest do
  @moduledoc false
  use ExUnit.Case
  doctest Wumpex.Gateway
  doctest Wumpex.Gateway.EventHandler
  doctest Wumpex.Gateway.State
  doctest Wumpex.Gateway.Worker

  @test_token "MYSECRETTESTTOKEN"
  @test_shard {0, 1}
  @test_gateway "ws://example.gateway"
  @test_session "MYVERYSECRETSESSION"

  @hello_opcode %{op: 10, d: %{heartbeat_interval: 10}}
  @ready_opcode %{op: 0, s: 1, t: :READY, d: %{session_id: @test_session}}

  setup do
    {:ok, guild_sup} = DynamicSupervisor.start_link(strategy: :one_for_one)

    {:ok, gateway} =
      Wumpex.Gateway.Worker.start_link(
        token: @test_token,
        shard: @test_shard,
        gateway: @test_gateway,
        guild_sup: guild_sup
      )

    {:ok,
     %{
       gateway: gateway
     }}
  end

  describe "The gateway should" do
    test "send heartbeat AND identify when receiving HELLO", %{gateway: gateway} do
      GenServer.cast(gateway, {{:binary, :erlang.term_to_binary(@hello_opcode)}, self()})

      assert_receive {:send, {:binary, heartbeat}}
      assert_receive {:send, {:binary, identify}}

      %{
        "op" => 1,
        "d" => nil
      } = :erlang.binary_to_term(heartbeat)

      %{
        "op" => 2,
        "d" => %{
          "token" => @test_token,
          "properties" => %{}
        }
      } = :erlang.binary_to_term(identify)
    end

    test "send heartbeat AND resume when receiving HELLO and a session is available", %{
      gateway: gateway
    } do
      GenServer.cast(gateway, {{:binary, :erlang.term_to_binary(@ready_opcode)}, self()})

      GenServer.cast(gateway, {{:binary, :erlang.term_to_binary(@hello_opcode)}, self()})
      assert_receive {:send, {:binary, _heartbeat}}
      assert_receive {:send, {:binary, resume}}

      %{
        "op" => 6,
        "d" => %{
          "token" => @test_token,
          "session_id" => @test_session,
          "seq" => 1
        }
      } = :erlang.binary_to_term(resume)
    end
  end
end
