defmodule Taper.Channel.Store do
  use Phoenix.Channel

  def join("taper:store:connect", _params, %{assigns: %{session_id: session_id}} = socket) do
    Taper.Store.Depo.connect(session_id)
    {:ok, %{id: session_id}, socket}
  end

  def join("taper:store:" <> id, _params, %{assigns: %{session_id: session_id}} = socket)
      when id == session_id do
    {:ok, Taper.Store.Depo.get_store(session_id), socket}
  end

  def join("taper:store:" <> _id, _params, _socket), do: {:error, %{reason: "unauthorized"}}

  def handle_in("dispatch", params, %{assigns: %{session_id: session_id}} = socket) do
    store = Taper.Store.Depo.dispatch(session_id, params)
    broadcast(socket, "update", store)
    {:noreply, socket}
  end
end
