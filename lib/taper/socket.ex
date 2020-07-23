defmodule Taper.Socket do
  use Phoenix.Socket

  channel("taper:store:*", Taper.Channel.Store)

  def connect(%{"taperToken" => token} = _params, socket, _connect_info) do
    case Phoenix.Token.verify(socket, "taper-token", token, max_age: 60 * 60) do
      {:ok, session_id} ->
        {:ok, assign(socket, :session_id, to_string(session_id))}

      {:error, _} ->
        :error
    end
  end

  def id(%{assigns: %{session_id: session_id}}), do: session_id
  def id(_), do: nil
end
