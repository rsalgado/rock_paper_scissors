defmodule RockPaperScissors.GameServer do
  use GenServer

  alias RockPaperScissors.GameStatus
  alias RockPaperScissors.GamesRegistry

  # Client API

  def start_link(game_opts) do
    casted_opts = 
      game_opts
      |> Keyword.take([:name, :playerA, :playerB])
      |> Enum.into(%{})

    process_name = {
      :via, 
      Registry, 
      {GamesRegistry, casted_opts[:name]}
    }

    GenServer.start_link(__MODULE__, casted_opts, [name: process_name])
  end

  def choose(game_pid, :playerA, choice) do
    GenServer.call(game_pid, {:choose, :playerA, choice})
  end
  def choose(game_pid, :playerB, choice) do
    GenServer.call(game_pid, {:choose, :playerB, choice})
  end

  def choices(game_pid), do:  GenServer.call(game_pid, :choices)

  def status(game_pid), do:  GenServer.call(game_pid, :status)



  # Server (callbacks)

  @impl true
  def init(opts) do
    initial_status = Map.merge(%GameStatus{}, opts)

    {:ok, initial_status}
  end

  @impl true
  def handle_call({:choose, player, choice}, _from, game_status) do
    game_status =
      game_status
      |> GameStatus.set_choice(player, choice)
      |> GameStatus.update_state()
      |> GameStatus.run_rules()

    {:reply, game_status.state, game_status}
  end

  @impl true
  def handle_call(:choices, _from, game_status) do
    {:reply, game_status.choices, game_status}
  end

  @impl true
  def handle_call(:status, _from, game_status) do
    {:reply, game_status, game_status}
  end

end
