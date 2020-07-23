defmodule Taper.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: :taper_store_registry},
      Taper.Store.Depo
    ]

    opts = [strategy: :one_for_one, name: Taper.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
