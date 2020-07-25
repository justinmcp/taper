defmodule Taper.Store.Builder do
  defmacro __using__(opts) do
    persist = Keyword.get(opts, :persistence, Taper.Persist.Agent)

    quote do
      @persistence unquote(persist)
      @before_compile unquote(__MODULE__)
      Module.register_attribute(__MODULE__, :reducers, accumulate: true)

      import unquote(__MODULE__), only: [reducer: 2]
    end
  end

  defmacro __before_compile__(env) do
    compile(Module.get_attribute(env.module, :reducers))
  end

  def compile(reducers) do
    default_store =
      Enum.reduce(reducers, %{}, fn {_module, opts}, store ->
        # TODO: if no name, should use camel-cased module
        name = Keyword.get(opts, :name)
        default = Keyword.get(opts, :default)
        Map.put(store, name, default)
      end)

    quote do
      def child_spec(args) do
        id = Keyword.get(args, :id)
        ds = unquote(Macro.escape(default_store))

        Supervisor.child_spec(
          %{
            id: id,
            start: {__MODULE__, :start_link, [ds, args]}
          },
          []
        )
      end

      def start_link(default_store, opts) do
        @persistence.start_link(default_store, opts)
      end

      def initial_state(), do: unquote(Macro.escape(default_store))

      def get_store(channel_id) do
        @persistence.get_store(channel_id)
      end

      def dispatch(channel_id, %{"type" => type} = params) do
        @persistence.fetch_and_update(channel_id, fn store ->
          action = Map.drop(params, ~w(type))

          Enum.reduce(unquote(Macro.escape(reducers)), store, fn {module, opts}, store ->
            name = Keyword.get(opts, :name)

            Map.update!(store, name, fn state ->
              if function_exported?(module, :__schema__, 1) do
                case apply(module, :reduce, [type, action, struct(module, state)]) do
                  changeset = %Ecto.Changeset{} ->
                    changeset
                    |> Ecto.Changeset.apply_changes()
                    |> Map.from_struct()

                  state = %_{} ->
                    Map.from_struct(state)

                  data ->
                    {:error, :invalid_data, data}
                end
              else
                apply(module, :reduce, [type, action, state])
              end
            end)
          end)
        end)
      end
    end
  end

  defmacro reducer(module, opts \\ []) do
    quote bind_quoted: [module: module, opts: opts] do
      @reducers {module, opts}
    end
  end
end
