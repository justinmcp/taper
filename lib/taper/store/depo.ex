defmodule Taper.Store.Depo do
  use Supervisor

  alias Taper.Store.Monitor

  def connect(session_id) do
    :depo_store_supervisor
    |> DynamicSupervisor.start_child({store(), id: session_id})
    |> case do
      {:ok, _pid} ->
        :ok

      {:error, {:already_started, _pid}} ->
        Monitor.cancel_shutdown(session_id)
        :ok

      _ ->
        :error
    end
  end

  def disconnect(session_id) do
    Monitor.schedule_shutdown(session_id)
  end

  def get_store(session_id), do: store().get_store(session_id)

  def dispatch(session_id, params) do
    store().dispatch(session_id, params)
  end

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts \\ []) do
    children = [
      {DynamicSupervisor, strategy: :one_for_one, name: :depo_store_supervisor},
      {Monitor, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def store(),
    do: Application.get_env(:taper, :store) || raise("You must set a store in the taper config")
end
