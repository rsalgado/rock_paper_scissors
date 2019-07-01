defmodule RockPaperScissorsWeb.GameChannel do
  use RockPaperScissorsWeb, :channel

  # def join("game:lobby", payload, socket) do
  #   if authorized?(payload) do
  #     {:ok, socket}
  #   else
  #     {:error, %{reason: "unauthorized"}}
  #   end
  # end

  # def join("game:"<>game_name, %{"role" => role}, socket) do
  #   if valid_role?(role) do
  #     # Set up the socket assign values before setting them
  #     role_atom = String.to_existing_atom(role)
  #     game = RockPaperScissors.find_game(game_name)
  #     # Set assigns for the game (pid) and user role
  #     socket =
  #       socket
  #       |> assign(:game, game)
  #       |> assign(:role, role_atom)

  #     {:ok, socket}
  #   else
  #     {:error, %{reason: "invalid role"}}
  #   end
  # end

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


  # # Channels can be used in a request/response fashion
  # # by sending replies to requests from the client
  # def handle_in("ping", payload, socket) do
  #   {:reply, {:ok, payload}, socket}
  # end

  # # Add authorization logic here as required.
  # defp authorized?(_payload) do
  #   true
  # end

  # defp valid_role?(role), do: role in ["playerA", "playerB"]
end
