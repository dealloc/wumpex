defmodule Wumpex.Base.Distributed do
  @moduledoc """
  Provides methods for distributed processing.

  This module is a thin wrapper around `:pg2`.
  Since OTP 23 released `:pg`, this module would allow easier upgrading from `:pg2` to `:pg`.
  """

  @doc """
  Join a process in the group.

      iex>Wumpex.Base.Distributed.join("my-global-group", self())
      :ok

  See `:pg2.join/2`
  """
  @spec join(group :: any(), pid :: pid()) :: :ok
  def join(group, pid) when is_pid(pid) do
    :ok = :pg2.create(group)
    :ok = :pg2.join(group, pid)
  end

  @doc """
  Get a list of `t:pid/0` containing all the members of the given `group`.
  If `group` does not exist, throws an error.

      iex>Wumpex.Base.Distributed.join("my-global-group", self())
      :ok
      iex>Wumpex.Base.Distributed.members_of!("my-global-group")
      [self()]

  See `:pg2.get_members/1`
  """
  @spec members_of!(group :: any()) :: list(pid())
  def members_of!(group) do
    case :pg2.get_members(group) do
      {:error, {:no_such_group, group}} ->
        raise "The global group #{inspect(group)} does not exist!"

      members when is_list(members) ->
        members
    end
  end
end
