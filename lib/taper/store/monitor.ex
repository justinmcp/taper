defmodule Taper.Store.Monitor do
  use GenServer

  # TODO: Using timeout might be a problem under load?

  def schedule_shutdown(session_id) do
    :taper_store_monitor
    |> GenServer.whereis()
    |> do_cast({:schedule, session_id})
  end

  def cancel_shutdown(session_id) do
    :taper_store_monitor
    |> GenServer.whereis()
    |> do_cast({:cancel, session_id})
  end

  @impl true
  def init(_) do
    {:ok, []}
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: :taper_store_monitor)
  end

  defp do_cast(nil, _), do: raise({:error, "Not started!"})
  defp do_cast(pid, args), do: GenServer.cast(pid, args)

  @impl true
  def handle_cast({:schedule, session_id}, state) do
    do_reply([{session_id, DateTime.utc_now()} | state])
  end

  @impl true
  def handle_cast({:cancel, session_id}, state) do
    state
    |> Enum.reject(fn {sid, _} -> sid == session_id end)
    |> do_reply()
  end

  @impl true
  def handle_info(:timeout, state) do
    state
    |> Enum.reject(fn {session_id, insert_time} ->
      if DateTime.diff(DateTime.utc_now(), insert_time, :millisecond) > timeout() do
        [{pid, _}] = Registry.lookup(:taper_store_registry, session_id)
        DynamicSupervisor.terminate_child(:depo_store_supervisor, pid)
        true
      else
        false
      end
    end)
    |> do_reply()
  end

  defp do_reply([]), do: {:noreply, []}
  defp do_reply(state), do: {:noreply, state, timeout()}

  defp timeout(), do: Application.get_env(:taper, :store_timeout, 10000)
end
