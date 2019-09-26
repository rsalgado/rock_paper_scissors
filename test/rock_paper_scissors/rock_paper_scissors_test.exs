defmodule RockPaperScissorsTest do
  use ExUnit.Case, async: false

  # Stop the application before all the tests
  setup_all do
    :ok = Application.stop(:rock_paper_scissors)
  end

  # Start the dynamic supervisor and the registry under the test supervisor
  setup do
    start_supervised!({DynamicSupervisor,
      strategy: :one_for_one,
      name: RockPaperScissors.GamesSupervisor})
    start_supervised!(Registry.child_spec(
      keys: :unique,
      name: RockPaperScissors.GamesRegistry))

    :ok
  end


  test "new_game/1: Creating a new game" do
    name = RockPaperScissors.random_alphanumeric()
    assert {:ok, game_pid} = RockPaperScissors.new_game(name)
    assert {:error, _} = RockPaperScissors.new_game(name)
  end

  test "find_game/1: Finding a game by name" do
    assert RockPaperScissors.find_game("MyTestGame") == nil
    {:ok, game_pid} = RockPaperScissors.new_game("MyTestGame")
    assert RockPaperScissors.find_game("MyTestGame") == game_pid
  end

  test "stop_game/1: Stopping an existing game" do
    {:ok, _} = RockPaperScissors.new_game("MyTestGame")
    assert :ok = RockPaperScissors.stop_game("MyTestGame")
    assert RockPaperScissors.find_game("MyTestGame") == nil
  end

  test "list_games/0: Listing all the current games" do
    names = MapSet.new(~w(game1 game2 game3 game4))
    Enum.each(names, &RockPaperScissors.new_game(&1))
    game_tuples = RockPaperScissors.list_games()

    assert Enum.all?(game_tuples, fn {_pid, name} -> name in names end)
  end
end
