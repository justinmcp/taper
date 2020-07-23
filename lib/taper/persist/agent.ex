defmodule Taper.Persist.Agent do
  def start_link(default_store, opts) do
    session_id = Keyword.get(opts, :id)

    Agent.start_link(fn -> default_store end,
      name: {:via, Registry, {:taper_store_registry, session_id}}
    )
  end

  def get_store(session_id) do
    Agent.get({:via, Registry, {:taper_store_registry, session_id}}, & &1)
  end

  def fetch_and_update(session_id, result_fn) do
    Agent.get_and_update({:via, Registry, {:taper_store_registry, session_id}}, fn store ->
      new_store = result_fn.(store)

      {new_store, new_store}
    end)
  end
end
