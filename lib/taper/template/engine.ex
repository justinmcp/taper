defmodule Taper.Template.Engine do
  @behaviour Phoenix.Template.Engine

  alias Taper.Store.Depo

  @node_executable "node"
  @compile_server "taper-server.js"

  def compile(template_path, _template_name) do
    template_path
    |> compile_jsx_file()
    |> EEx.compile_string(engine: Phoenix.HTML.Engine, file: template_path, line: 1)
  end

  defp compile_jsx_file(template_path) do
    with {:ok, port} <-
           open_port(System.find_executable(@node_executable), server_path(@compile_server)),
         {:ok, res} <- do_compile(port, template_path) do
      Port.close(port)
      res
    end
  end

  defp open_port(node_executable, server_script_path) do
    port =
      {:spawn_executable, node_executable}
      |> Port.open(
        args: [server_script_path],
        packet: 4,
        env: [{'NODE_PATH', String.to_charlist(node_path())}]
      )

    {:ok, port}
  end

  defp do_compile(port, script) do
    # Not that great
    store = Depo.store().initial_state()

    command = json_library().encode!(%{type: "compile_jsx_file", path: script, store: store})

    Port.command(port, command)

    port
    |> receive_response()
    |> handle_response()
  end

  defp asset_path(), do: Path.join([:code.priv_dir(:taper), "static", "js"])

  # XXX: Project compile happens with cwd set to root of project
  # https://groups.google.com/d/msg/elixir-lang-talk/Ls0eJDdMMW8/VLWWAKWPAQAJ
  defp node_path() do
    taper_paths = []

    app_paths =
      ["assets/node_modules"]
      |> Enum.map(&Path.join(File.cwd!(), &1))

    (taper_paths ++ app_paths)
    |> Enum.join(":")
  end

  defp server_path(server_script) do
    Path.join(asset_path(), server_script)
  end

  defp receive_response(port) do
    receive do
      {^port, {:data, result}} ->
        json_library().decode!(result)
    end
  end

  defp handle_response(%{"type" => "response", "data" => result}) do
    result
  end

  defp handle_response(_), do: {:error, "Unexpected response from server"}

  defp json_library(), do: Phoenix.json_library()
end
