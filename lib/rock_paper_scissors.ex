defmodule RockPaperScissors do
  @moduledoc """
  RockPaperScissors keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  alias RockPaperScissors.GamesSupervisor
  alias RockPaperScissors.GameServer
  alias RockPaperScissors.GamesRegistry


  def new_game(name, playerA, playerB) do
    game_opts = [
      name: name,
      playerA: playerA, 
      playerB: playerB
    ]

    {:ok, _} = DynamicSupervisor.start_child(GamesSupervisor, {GameServer, game_opts})
  end

  def find_game(name) do
    case Registry.lookup(GamesRegistry, name) do
      [] -> nil
      [{game, nil}] -> game
    end
  end

  def stop_game(name) do
    game = find_game(name)
    GenServer.stop(game)
  end
end
