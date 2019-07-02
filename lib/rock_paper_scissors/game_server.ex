defmodule RockPaperScissors.GameServer do
  use GenServer

  alias RockPaperScissors.GameState
  alias RockPaperScissors.GamesRegistry

  # Client API

  def child_spec(game_name) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [game_name]},
      restart: :transient
    }
  end

  def start_link(game_name) do
    process_name = {
      :via,
      Registry,
      {GamesRegistry, game_name}
    }

    GenServer.start_link(__MODULE__, game_name, [name: process_name])
  end

  def state(game_pid) do
    GenServer.call(game_pid, :state)
  end

  def name(game_pid) do
    state(game_pid) |> Map.get(:name)
  end

  def status(game_pid) do
    state(game_pid) |> Map.get(:status)
  end

  def winner(game_pid) do
    state(game_pid) |> Map.get(:winner)
  end

  def players_ids(game_pid) do
      game_pid
      |> state()
      |> Map.get(:players)
      |> Map.values()
      |> Enum.map(& &1.id)
  end

  def choose(game_pid, role, choice) do
    GenServer.call(game_pid, {:choose, role, choice})
  end

  def set_host(game_pid, name) do
    GenServer.call(game_pid, {:set_host, name})
  end

  def set_guest(game_pid, name) do
    GenServer.call(game_pid, {:set_guest, name})
  end


  # Server (callbacks)

  @impl true
  def init(game_name) do
    initial_status = %GameState{name: game_name}

    {:ok, initial_status}
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
