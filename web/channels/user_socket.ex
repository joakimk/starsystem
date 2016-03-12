defmodule Starsystem.UserSocket do
  use Phoenix.Socket

  # channel "rooms:*", Starsystem.RoomChannel

  transport :websocket, Phoenix.Transports.WebSocket

  def connect(_params, socket) do
    {:ok, socket}
  end

  def id(_socket), do: nil
end
