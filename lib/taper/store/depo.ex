defmodule Taper.Store.Depo do
  use Supervisor

  def connect(session_id) do
    # TODO: Check result; eg {:error, {:already_starteed, pid}}
    # TODO: Add timeouts - X seconds after disconnect; store is deleted
    DynamicSupervisor.start_child(
      :depo_store_supervisor,
      {store(), id: session_id}
    )
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
      {DynamicSupervisor, strategy: :one_for_one, name: :depo_store_supervisor}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def store(),
    do: Application.get_env(:taper, :store) || raise("You must set a store in the taper config")
end
