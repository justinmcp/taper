defmodule Taper.Router do
  defmacro taper(path, controller, opts \\ []) when is_list(opts) do
    quote bind_quoted: [path: path, controller: controller, opts: opts] do
      Phoenix.Router.get(path, controller, :index, private: %{taper: Enum.into(opts, %{})})
    end
  end
end
