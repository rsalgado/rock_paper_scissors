defmodule RockPaperScissorsWeb.GameChannel do
  @moduledoc """
  This is channel module for games. Join this channel using topics of the form:
  `"games:<game_name>"`. No payload is expected to join but there must be a `:player`
  in the socket's assigns that should have been set up when connecting to the socket.
  """

  use RockPaperScissorsWeb, :channel
  alias RockPaperScissors.GameServer


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
      # Build the initial reply payload and send it
      reply = %{
        role: socket.assigns.role,
        players: GameServer.players(game),
        status: GameServer.status(game)
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

end
