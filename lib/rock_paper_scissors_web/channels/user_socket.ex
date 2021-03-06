defmodule RockPaperScissorsWeb.UserSocket do
  @moduledoc """
  This is the only socket module. When trying to connect to this socket, it expects a
  valid token as part of the payload map. i.e: `%{"token" => token}`. Where the `token`
  must be a [`%Player{}`](`RockPaperScissors.Player`) struct corresponding to the user (player) trying to connect.
  Remember that the salt must match the one used for signing: `"user socket"` in this case.
  """

  use Phoenix.Socket
  require Logger

  ## Channels
  channel "games:*", RockPaperScissorsWeb.GameChannel


  def connect(%{"token" => token}, socket, _connect_info) do
    one_week = 60 * 60 * 24 * 7

    case Phoenix.Token.verify(socket, "user socket", token, max_age: one_week) do
      {:ok, player} ->
        {:ok, assign(socket, :player, player)}

      {:error, reason} ->
        Logger.error("Socket's token verification failed: #{reason}")
        :error
    end
  end

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "user_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     RockPaperScissorsWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  def id(_socket), do: nil
end
