defmodule RockPaperScissors.GameStatus do

  @derive Jason.Encoder
  defstruct [
    name: "",
    playerA: nil,
    playerB: nil,

    choices: %{
      playerA: nil,
      playerB: nil,
    },

    winner: nil,
    state: :started,
  ]

  @doc """
  Update the game status by setting the given player's choice. Player must be either
   of `:playerA` or `:playerB`. Choice must be `:rock`, `:paper`, `:scissor` or `nil`
  """
  def set_choice(status, player, choice) do
    if valid_choice?(choice) do
      path = [Access.key(:choices), Access.key(player)]
      put_in(status, path, choice)
    end
  end

  defp valid_choice?(choice), do:   choice in [nil, :rock, :paper, :scissors]

  @doc """
  Update the game status by changing the state to one of:
  * `:started`, when no player choice has been made
  * `:waitingA`, when `:playerB` has chosen and only `:playerA` is left
  * `:waitingB`, when `:playerA` has chosen and only `:playerB` is left
  * `:ready`, when both players have chosen their option
  """
  def update_state(status) do
    case status.choices do
      %{playerA: nil, playerB: nil} ->
        %{status | state: :started}
      %{playerA: nil} ->
        %{status | state: :waitingA}
      %{playerB: nil} ->
        %{status | state: :waitingB}
      _ ->
        %{status | state: :ready}
    end
  end

  @doc """
  Try to run the rules of the game to define the `:winner` and update `:state` to
  `:finished` if  it is `:ready` (both player have made their choices); otherwise
  bypass the status without doing anything.
  """
  # Run when the `:state` is `:ready`
  def run_rules(%{state: :ready} = status) do
    options = {status.choices.playerA, status.choices.playerB}

    if (elem(options, 0) == elem(options, 1)) do
      %{status | winner: :tie, state: :finished}

    else
      winner = case options do
        {:rock, :paper} ->      :playerB
        {:rock, :scissors} ->   :playerA

        {:paper, :rock} ->      :playerA
        {:paper, :scissors} ->  :playerB

        {:scissors, :rock} ->   :playerB
        {:scissors, :paper} ->  :playerA
      end

      %{status | winner: winner, state: :finished}
    end
  end
  # Bypass if the game's status is not `:ready`
  def run_rules(status), do: status
end
