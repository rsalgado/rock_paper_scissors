defmodule RockPaperScissorsWeb.GameChannel do
  @moduledoc """
  This is channel module for games. Join this channel using topics of the form:
  `"games:<game_name>"`.
  No payload is expected to join, but there must be a `:player` in the socket's
  assigns that should have been set up when connecting to the socket
  (`RockPaperScissorsWeb.UserSocket.connect/3`).
  """

  use RockPaperScissorsWeb, :channel
  alias RockPaperScissors.GameServer
  require Logger

  def join("games:"<>game_name, _payload, socket) do
    game = RockPaperScissors.find_game(game_name)
    player = socket.assigns[:player]
    role = GameServer.player_role(game, player)

    # Authorize joining if the player is a guest or a host and update the assigns
    if role in [:host, :guest] do
      socket =
        socket
        |> assign(:game, game)
        |> assign(:role, role)

      # Schedule broadcast with "status_update" event to force existing player's status to update
      # Also, schedule the game to be stopped after 10 minutes of its creation
      send(self(), :on_join)
      Process.send_after(self(), :stop_game, 600_000)

      # Build the initial reply payload and send it
      reply = %{
        role: socket.assigns.role,
        players: GameServer.players(game),
        status: GameServer.status(game),
        winner: GameServer.winner(game),
        choices: GameServer.choices(game)
      }

      {:ok, reply, socket}

    # Otherwise, prevent the player from joining to this channel
    else
      {:error, %{reason: "unauthorized"}}
    end
  end


  @doc """
  Handle `"choice"` messages/events. This doesn't reply, but performs broadcasts.
  """
  def handle_in("choose", %{"choice" => choice}, socket) do
    # Get data necessary for choosing
    choice_atom = String.to_existing_atom(choice)
    game = socket.assigns.game
    role = socket.assigns.role
    # Make choice and get the new server's state
    state = GameServer.choose(game, role, choice_atom)

    # Broadcast the new status
    broadcast(socket, "status_update", %{status: state.status})
    # If the game is finished, broadcast `"game_finished"` event with the full game's state
    if state.status == :finished do
      broadcast(socket, "game_finished", state)
    end

    {:noreply, socket}
  end

  def handle_info(:on_join, socket) do
    game = socket.assigns.game
    status = GameServer.status(game)
    broadcast(socket, "status_update", %{status: status})

    {:noreply, socket}
  end

  def handle_info(:stop_game, socket) do
    game_name = GameServer.name(socket.assigns.game)
    :ok = RockPaperScissors.stop_game(game_name)
    Logger.info("Game #{game_name} stopped")

    {:noreply, socket}
  end
end
