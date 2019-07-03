defmodule RockPaperScissorsWeb.GameChannel do
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

      reply = %{players: GameServer.players(game), role: socket.assigns.role}

      {:ok, reply, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # def handle_in("choose", %{"choice" => choice}, socket) do
  #   # Extract paramaters for choosing
  #   game = socket.assigns.game
  #   role = socket.assigns.role
  #   choice_atom = String.to_existing_atom(choice)
  #   # Make choice with parameters
  #   new_state = RockPaperScissors.GameServer.choose(game, role, choice_atom)
  #   # Broadcast the new game state to players
  #   broadcast(socket, "update_state", %{"state" => new_state})

  #   # Broadcast the final status (all details) of the game if it is finished
  #   if new_state == :finished do
  #     status = RockPaperScissors.GameServer.status(game)
  #     broadcast(socket, "final_status", status)
  #   end

  #   {:noreply, socket}
  # end


  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

end
