defmodule Starsystem.GameChannel do
  use Phoenix.Channel

  @env Mix.env
  def join(_channel, _message, socket) do
    if @env == :dev do
      :fs.subscribe()
    end

    {:ok, socket}
  end

  def handle_info({_pid, {:fs, :file_event}, {path, _event}}, socket) do
    if String.contains?(List.to_string(path), "compiled_elm.js") do
      broadcast! socket, "updated_code", %{ source: File.read!(path) }
    end

    {:noreply, socket}
  end

  def handle_in("ping", data, socket) do
    push socket, "pong", data
    {:noreply, socket}
  end

  def handle_in("player_update", player, socket) do
    broadcast! socket, "player_update", player
    {:noreply, socket}
  end
end
