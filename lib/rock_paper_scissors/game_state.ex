defmodule RockPaperScissors.GameState do
  @moduledoc """
  A struct for handling a game's state. The module also includes basic functions for
  manipulating the state and updating the game's status (not to be confused with state).
  """

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
    },
    choices: %{
      host: :none,
      guest: :none,
    }
  ]

  @valid_roles [:guest, :host]
  @valid_choices [:none, :rock, :paper, :scissors]

  @doc """
  Set the host player (and update the game's status)
  """
  def set_host(%GameState{} = state, %Player{} = player) do
    state.players.host
    |> put_in(player)
    |> update_status()
  end

  @doc """
  Set the guest player (and update the game's status)
  """
  def set_guest(%GameState{} = state, %Player{} = player) do
    state.players.guest
    |> put_in(player)
    |> update_status()
  end

  @doc """
  Make a choice for a given role (and update the game's status)
  """
  def set_choice(state, role, choice) when (role in @valid_roles) and (choice in @valid_choices) do
    players_status = players_status(state)

    if players_status == :players_ready do
      path = [Access.key!(:choices), Access.key!(role)]

      state
      |> put_in(path, choice)
      |> update_status()
    else
      Logger.warn("Choice was not set because game is missing players: #{players_status}")
      state
    end
  end

  @doc """
  Update the game's status. This is called by other functions implicitly.

  It recalculates and sets the status first checking if the users are ready as a first stage,
  then if the choices have been made as a second stage, and, finally, running the rules
  as a final stage.
  """
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
    winner = case state.choices do
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
    case state.choices do
      %{host: :none, guest: :none}  -> :waiting_choices
      %{guest: :none} -> :waiting_guest_choice
      %{host: :none} -> :waiting_host_choice
      %{host: _, guest: _} -> :choices_ready
    end
  end
end
