defmodule Taper.Channel.RemoteCall do
  use Phoenix.Channel

  def join("taper:remote_call:" <> channel_id, _params, %{assigns: %{session_id: _}} = socket) do
    {:ok, channel_id, socket}
  end

  # Send to local reducers
  def handle_in(
        "call",
        %{"remoteCallId" => call_id} = _params,
        %{topic: "remote_call:" <> _channel_id} = socket
      ) do
    send(self(), {:test_call_response, call_id})

    {:noreply, socket}
  end

  def handle_info({:test_call_response, call_id}, socket) do
    Task.start(fn ->
      Process.sleep(2000)
      IO.puts("SENDING MESSAGE")
      push(socket, "update", %{"remoteCallId" => call_id, type: "hello"})
    end)

    {:noreply, socket}
  end
end
