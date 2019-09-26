defmodule RockPaperScissors.GameServerTest do
  use ExUnit.Case, async: true
  alias RockPaperScissors.{GameServer, GameState, Player}

  test "name/1: Get a game's name" do
     {:ok, game_pid} = GameServer.start_link("MyTestGame")
     assert GameServer.name(game_pid) == "MyTestGame"
     assert RockPaperScissors.find_game("MyTestGame") == game_pid
  end

  test "status/1: Get a game's status" do
    {:ok, game_pid} = GameServer.start_link("MyTestGame")
    assert GameServer.status(game_pid) == :missing_players

    GameServer.set_guest(game_pid, %Player{name: "Alice"})
    assert GameServer.status(game_pid) == :missing_host

    GameServer.set_host(game_pid, %Player{name: "Bob"})
    assert GameServer.status(game_pid) == :waiting_choices

    GameServer.choose(game_pid, :guest, :rock)
    assert GameServer.status(game_pid) == :waiting_host_choice

    GameServer.choose(game_pid, :host, :paper)
    assert GameServer.status(game_pid) == :finished
  end

  test "winner/1: Get a game's winner" do
    {:ok, game_pid} = GameServer.start_link("MyTestGame")
    assert GameServer.winner(game_pid) == nil

    GameServer.set_host(game_pid, %Player{name: "Alice"})
    GameServer.set_guest(game_pid, %Player{name: "Bob"})
    GameServer.choose(game_pid, :host, :paper)
    GameServer.choose(game_pid, :guest, :scissors)
    assert GameServer.winner(game_pid) == :guest
  end

  test "choices/1: Get a game's choices" do
    {:ok, game_pid} = GameServer.start_link("MyTestGame")
    assert GameServer.choices(game_pid) == %{host: :none, guest: :none}

    GameServer.set_host(game_pid, %Player{name: "Bob"})
    GameServer.set_guest(game_pid, %Player{name: "Alice"})
    GameServer.choose(game_pid, :host, :rock)
    GameServer.choose(game_pid, :guest, :scissors)
    assert GameServer.choices(game_pid) == %{host: :rock, guest: :scissors}
  end

  test "players/1: Get a game's players" do
    {:ok, game_pid} = GameServer.start_link("MyTestGame")
    assert GameServer.players(game_pid) == %{host: %Player{}, guest: %Player{}}

    [host, guest] = [%Player{name: "Alice", id: "12"}, %Player{name: "Bob", id: "34"}]
    GameServer.set_host(game_pid, host)
    GameServer.set_guest(game_pid, guest)
    assert %{host: ^host, guest: ^guest} = GameServer.players(game_pid)
  end

  test "state/1: Get a game's state" do
    expected_initial_state = %GameState{
      choices: %{guest: :none, host: :none},
      name: "MyTestGame",
      players: %{
        guest: %Player{id: nil, name: :none},
        host: %Player{id: nil, name: :none}
      },
      status: :missing_players,
      winner: nil
    }

    {:ok, game_pid} = GameServer.start_link("MyTestGame")
    actual_state = GameServer.state(game_pid)
    assert expected_initial_state == actual_state
  end

  test "player_role/2: Get the role of a given player" do
    player = %Player{name: "Bobby Tables", id: "1234"}
    {:ok, game_pid} = GameServer.start_link("MyTestGame")

    assert GameServer.player_role(game_pid, player) == nil
    GameServer.set_guest(game_pid, player)
    assert GameServer.player_role(game_pid, player) == :guest
  end

  test "choose/3: Make a choice for a given player role" do
    guest = %Player{name: "Alice"}
    host = %Player{name: "Bob"}
    {:ok, game_pid} = GameServer.start_link("MyTestGame")

    GameServer.set_guest(game_pid, guest)
    GameServer.set_host(game_pid, host)
    GameServer.choose(game_pid, :guest, :rock)
    GameServer.choose(game_pid, :host, :paper)
    assert GameServer.choices(game_pid) == %{guest: :rock, host: :paper}
  end

  test "set_host/2: Set a game's host" do
    player = %Player{name: "John Doe"}
    {:ok, game_pid} = GameServer.start_link("MyTestGame")

    GameServer.set_host(game_pid, player)
    assert GameServer.players(game_pid).host == player
  end

  test "set_guest/2: Set a game's guest" do
    player = %Player{name: "John Doe"}
    {:ok, game_pid} = GameServer.start_link("MyTestGame")

    GameServer.set_guest(game_pid, player)
    assert GameServer.players(game_pid).guest == player
  end
end
