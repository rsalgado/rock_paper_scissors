defmodule RockPaperScissors.Player do
  @derive Jason.Encoder
  defstruct name: :none, choice: :none
end

defmodule RockPaperScissors.GameState do
  require Logger
  alias RockPaperScissors.Player
  alias __MODULE__

  @derive Jason.Encoder
  defstruct [
    name: "",
    status: :missing_players,
    winner: nil,
    players: %{
      host: %Player{},
      guest: %Player{}
    }
  ]

  @valid_roles [:guest, :host]
  @valid_choices [:none, :rock, :paper, :scissors]

  def set_host(%GameState{} = state, name) do
    path = [Access.key!(:players), Access.key!(:host), Access.key!(:name)]

    state
    |> put_in(path, name)
    |> update_status()
  end

  def set_guest(%GameState{} = state, name) do
    path = [Access.key!(:players), Access.key!(:guest), Access.key!(:name)]

    state
    |> put_in(path, name)
    |> update_status()
  end

  def set_choice(state, player, choice) when (player in @valid_roles) and (choice in @valid_choices) do
    players_status = players_status(state)

    if players_status == :players_ready do
      path = [Access.key!(:players), Access.key!(player), Access.key!(:choice)]

      state
      |> put_in(path, choice)
      |> update_status()
    else
      Logger.warn("Choice was not set because game is missing players: #{players_status}")
      state
    end
  end

  def update_status(%GameState{} = state) do
    state
    |> update_status_using(:players)
    |> update_status_using(:choices)
    |> run_rules()
  end

  defp update_status_using(state, :players) do
    %GameState{state | status: players_status(state)}
  end

  defp update_status_using(%GameState{status: :players_ready} = state, :choices) do
    %GameState{state | status: choices_status(state)}
  end
  defp update_status_using(state, :choices), do: state

  defp run_rules(%GameState{status: :choices_ready} = state) do
    choices = choices(state)

    winner = case choices do
      %{host: :rock , guest: :paper} ->     :guest
      %{host: :rock , guest: :scissors} ->  :host

      %{host: :paper , guest: :rock} ->     :host
      %{host: :paper , guest: :scissors} -> :guest

      %{host: :scissors , guest: :rock} ->  :guest
      %{host: :scissors , guest: :paper} -> :host

      _ ->  :tie
    end

    %GameState{state | winner: winner, status: :finished}
  end
  defp run_rules(state), do: state


  defp players_status(%GameState{players: players}) do
    player_names = {players.host.name, players.guest.name}

    case player_names do
      {:none, :none} -> :missing_players
      {_, :none} -> :missing_guest
      {:none, _} -> :missing_host
      {_, _} -> :players_ready
    end
  end

  defp choices_status(state) do
    case choices(state) do
      %{host: :none, guest: :none}  -> :waiting_choices
      %{guest: :none} -> :waiting_guest_choice
      %{host: :none} -> :waiting_host_choice
      %{host: _, guest: _} -> :choices_ready
    end
  end

  defp choices(state) do
    %{ host: state.players.host.choice, guest: state.players.guest.choice }
  end
end
