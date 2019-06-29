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


  @spec new_game(String.t, String.t, String.t) :: {:ok, pid}
  @doc """
  Create a new game `GameServer` process with the given name and players
  """
  def new_game(name, playerA, playerB) do
    game_opts = [
      name: name,
      playerA: playerA,
      playerB: playerB
    ]

    {:ok, _} = DynamicSupervisor.start_child(GamesSupervisor, {GameServer, game_opts})
  end

  @spec find_game(String.t) :: (pid | nil)
  @doc """
  Find a game (`GameServer`) by name in the `GamesRegistry`
  """
  def find_game(name) do
    case Registry.lookup(GamesRegistry, name) do
      [] -> nil
      [{game, nil}] -> game
    end
  end

  @spec stop_game(any) :: :ok
  @doc """
  Stop the game with the given name (after looking it up in the `GamesRegistry`)
  """
  def stop_game(name) do
    game = find_game(name)
    GenServer.stop(game)
  end

  @spec list_games() :: [{pid, String.t}]
  @doc """
  List all the current games as a list of tuples of the form `{game_pid, "game_name"}`
  """
  def list_games() do
    GamesSupervisor
    |> DynamicSupervisor.which_children()
    |> Enum.map(fn {_, pid, _, _} ->  {pid, GameServer.name(pid)} end)
  end
end
