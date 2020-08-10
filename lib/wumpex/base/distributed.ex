defmodule Wumpex.Base.Distributed do
  @moduledoc """
  Provides methods for distributed processing.

  This module is a thin wrapper around `:pg2` or `:pg` if available.

  Since `:pg` is only available since OTP 23, this module allows falling back to `:pg2` on older versions.
  """

  @doc """
  Join a process in the group.

      iex>Wumpex.Base.Distributed.join("my-global-group", self())
      :ok

  See `:pg2.join/2` or `:pg.join/2`
  """
  @spec join(group :: any(), pid :: pid()) :: :ok
  def join(group, pid) when is_pid(pid) do
    pg_join(group, pid)
  end

  @doc """
  Get a list of `t:pid/0` containing all the members of the given `group`.
  If `group` does not exist, returns an empty list.

      iex>Wumpex.Base.Distributed.join("my-global-group", self())
      :ok
      iex>Wumpex.Base.Distributed.members_of("my-global-group")
      [self()]

  See `:pg2.get_members/1` or `:pg.get_members/1`
  """
  @spec members_of(group :: any()) :: list(pid())
  def members_of(group) do
    pg_members(group)
  end

  # Check if :pg is available
  if Code.ensure_loaded?(:pg) do
    defp pg_join(group, pid) do
      :ok = :pg.join(group, pid)
    end

    defp pg_members(group) do
      :pg.get_members(group)
    end

  # Fall back to :pg2 if :pg is not available
  else
    defp pg_join(group, pid) do
      :ok = :pg2.create(group)
      :ok = :pg2.join(group, pid)
    end

    defp pg_members(group) do
      case :pg2.get_members(group) do
        {:error, {:no_such_group, group}} ->
          []

        members when is_list(members) ->
          members
      end
    end
  end
end
