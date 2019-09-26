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


  @doc """
  Create a new game `GameServer` process with the given name
  """
  @spec new_game(String.t) :: {:ok, pid} | {:error, String.t}
  def new_game(game_name) do
    case DynamicSupervisor.start_child(GamesSupervisor, {GameServer, game_name}) do
      {:ok, pid} -> {:ok, pid}
      otherwise -> {:error, inspect(otherwise)}
    end
  end

  @doc """
  Find a game (`GameServer`) by name in the `GamesRegistry`
  """
  @spec find_game(String.t) :: pid | nil
  def find_game(name) do
    case Registry.lookup(GamesRegistry, name) do
      [] -> nil
      [{game, nil}] -> game
    end
  end

  @doc """
  Stop the game with the given name (after looking it up in the `GamesRegistry`)
  """
  @spec stop_game(String.t) :: :ok
  def stop_game(name) do
    game = find_game(name)
    GenServer.stop(game)
  end

  @doc """
  List all the current games as a list of tuples of the form `{game_pid, "game_name"}`
  """
  @spec list_games() :: [{pid, String.t}]
  def list_games() do
    GamesSupervisor
    |> DynamicSupervisor.which_children()
    |> Enum.map(fn {_, pid, _, _} ->  {pid, GameServer.name(pid)} end)
  end

  @doc """
  Generate a random string of the given size made up of (lowercase) alphanumeric characters
  """
  def random_alphanumeric(size \\ 8) do
    valid_chars = '0123456789abcdefghijklmnopqrstuvwxyz'

    charlist =
      if (size <= length(valid_chars)) do
        valid_chars
      else
        Stream.cycle(valid_chars) |> Enum.take(size)
      end

    charlist
    |> Enum.take_random(size)
    |> to_string()
  end
end
