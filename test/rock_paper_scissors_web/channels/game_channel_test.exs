defmodule RockPaperScissorsWeb.GameChannelTest do
  use RockPaperScissorsWeb.ChannelCase

  alias RockPaperScissors.{Player, GameServer}
  alias RockPaperScissorsWeb.UserSocket

  setup do
    # Create the host player
    host = %Player{name: "Alice", id: "1234"}
    # Start a new game with the player as a host
    game_name = RockPaperScissors.random_alphanumeric()
    {:ok, game} = RockPaperScissors.new_game(game_name)
    GameServer.set_host(game, host)
    # Connect the player to the socket
    host_token = Phoenix.Token.sign(@endpoint, "user socket", host)
    {:ok, host_socket} = connect(UserSocket, %{token: host_token})

    {:ok, game_pid: game, game_name: game_name, host_socket: host_socket}
  end

  describe "Joining the channel" do
    test "with valid player", %{game_pid: game, game_name: name, host_socket: socket} do
      expected_reply = %{
        role: :host,
        players: GameServer.players(game),
        status: GameServer.status(game),
        winner: GameServer.winner(game),
        choices: GameServer.choices(game)
      }
      # Join the channel as host (with the host's socket struct) and subscribe
      # the test to the channel in order to assert against it.
      {:ok, reply, socket} = subscribe_and_join(socket, "games:#{name}")
      # Match against the expected reply and check socket's fields channel's broadcast
      ^expected_reply = reply
      assert socket.assigns.game == game
      assert socket.assigns.role == :host
      assert_broadcast("status_update", %{status: :missing_guest})
    end

    test "with invalid (non-member) player", %{game_name: name, host_socket: socket} do
      player = %Player{name: "Bob", id: "9876"}
      socket = put_in(socket.assigns.player, player)
      {:error, %{reason: "unauthorized"}} = subscribe_and_join(socket, "games:#{name}")
    end
  end

  describe "Playing with both players" do
    setup %{game_pid: game} do
      # Create guest player and set it as the game's guest
      guest = %Player{name: "Bob", id: "5678"}
      GameServer.set_guest(game, guest)
      # Connect the player to the socket
      guest_token = Phoenix.Token.sign(@endpoint, "user socket", guest)
      {:ok, guest_socket} = connect(UserSocket, %{token: guest_token})

      {:ok, guest_socket: guest_socket}
    end

    test "making choices", %{game_name: name, host_socket: host_socket, guest_socket: guest_socket} do
      # Join the channel as host and guest and get back their corresponding socket structs
      {:ok, _reply, host_socket} = subscribe_and_join(host_socket, "games:#{name}")
      {:ok, _reply, guest_socket} = subscribe_and_join(guest_socket, "games:#{name}")

      assert host_socket.assigns.role == :host
      assert guest_socket.assigns.role == :guest
      # Make choice of host player and check the expected broadcast
      push(host_socket, "choose", %{"choice" => "rock"})
      assert_broadcast("status_update", %{status: :waiting_guest_choice})
      # Make choice of guest player and check the expected broadcast
      push(guest_socket, "choose", %{"choice" => "paper"})
      assert_broadcast("status_update", %{status: :finished})
      # Check final broadcast when the game is finished
      assert_broadcast("game_finished", %{
        status: :finished,
        choices: %{host: :rock, guest: :paper},
        winner: :guest
      })
    end
  end

  test "Stopping the game when the right message comes",
  %{game_pid: game, game_name: name, host_socket: socket} do
    {:ok, _, socket} = subscribe_and_join(socket, "games:#{name}")

    assert Process.alive?(game)
    send(socket.channel_pid, :stop_game)
    Process.sleep(20)     # TODO: Find a better way to wait for the process' stop
    assert !Process.alive?(game)
  end
end
