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
  end

  test "winner/1: Get a game's winner" do
    {:ok, game_pid} = GameServer.start_link("MyTestGame")
    assert GameServer.winner(game_pid) == nil
  end

  test "choices/1: Get a game's choices" do
    {:ok, game_pid} = GameServer.start_link("MyTestGame")
    assert GameServer.choices(game_pid) == %{host: :none, guest: :none}
  end

  test "players/1: Get a game's players" do
    {:ok, game_pid} = GameServer.start_link("MyTestGame")
    assert GameServer.players(game_pid) == %{host: %Player{}, guest: %Player{}}
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
