defmodule RockPaperScissors.GameServer do
  @moduledoc """
  A GenServer module to represent games and manipulate them.

  A `GameServer` process wraps a game's state using a `RockPaperScissors.GameState`
  struct, and exposes a client API for interacting with the game; the server functions
  are mostly wrappers of the `GameState` module functions.   Normally, the process runs
  under a dynamic supervisor and is registered with a unique name in a registry in
  order to identify it.
  """

  use GenServer

  alias RockPaperScissors.{GameState, GamesRegistry, Player}

  # Client API

  def child_spec(game_name) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [game_name]},
      restart: :transient
    }
  end

  @doc """
  Start and link a new GameServer, registering it with the given `game_name`.
  """
  def start_link(game_name) do
    process_name = {
      :via,
      Registry,
      {GamesRegistry, game_name}
    }

    GenServer.start_link(__MODULE__, game_name, [name: process_name])
  end

  @doc """
  Get the game's name
  """
  def name(game_pid) do
    state(game_pid) |> Map.get(:name)
  end

  @doc """
  Get the game's status
  """
  def status(game_pid) do
    state(game_pid) |> Map.get(:status)
  end

  @doc """
  Get the game's winner
  """
  def winner(game_pid) do
    state(game_pid) |> Map.get(:winner)
  end

  @doc """
  Get the player's choices
  """
  def choices(game_pid) do
    state(game_pid) |> Map.get(:choices)
  end

  @doc """
  Get the game's players
  """
  def players(game_pid) do
      state(game_pid) |> Map.get(:players)
  end

  @doc """
  Get the whole game's state (`RockePaperScissors.GameState`)
  """
  def state(game_pid) do
    GenServer.call(game_pid, :state)
  end

  @doc """
  Determine a player's role (`:guest` or `:host`), or return `nil` if the player is
  not part of the game.
  """
  def player_role(game_pid, %Player{id: player_id} = _player) do
    %{guest: guest, host: host} = players(game_pid)

    cond do
      player_id == host.id ->   :host
      player_id == guest.id ->  :guest
      _otherwise = true ->      nil
    end
  end

  @doc """
  Make a choice (e.g. `:rock`) for a given player role (e.g. `:guest`)
  """
  def choose(game_pid, role, choice) do
    GenServer.call(game_pid, {:choose, role, choice})
  end

  @doc """
  Set the game's host player
  """
  def set_host(game_pid, name) do
    GenServer.call(game_pid, {:set_host, name})
  end

  @doc """
  Set the game's guest player
  """
  def set_guest(game_pid, name) do
    GenServer.call(game_pid, {:set_guest, name})
  end


  # Server (callbacks)

  @impl true
  def init(game_name) do
    initial_state = %GameState{name: game_name}
    {:ok, initial_state}
  end

  @impl true
  def handle_call(:state, _from, game_state) do
    {:reply, game_state, game_state}
  end

  @impl true
  def handle_call({:choose, role, choice}, _from, game_state) do
    new_state = GameState.set_choice(game_state, role, choice)
    {:reply, new_state, new_state}
  end

  @impl true
  def handle_call({:set_host, name}, _from, game_state) do
    new_state = GameState.set_host(game_state, name)
    {:reply, new_state, new_state}
  end

  @impl true
  def handle_call({:set_guest, name}, _from, game_state) do
    new_state = GameState.set_guest(game_state, name)
    {:reply, new_state, new_state}
  end
end
