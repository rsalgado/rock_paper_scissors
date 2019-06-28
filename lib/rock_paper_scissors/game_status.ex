defmodule RockPaperScissors.GameStatus do
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

  def set_choice(status, player, choice) do
    if valid_choice?(choice) do
      path = [Access.key(:choices), Access.key(player)]
      put_in(status, path, choice)
    end
  end

  defp valid_choice?(choice), do:   choice in [nil, :rock, :paper, :scissors]

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
