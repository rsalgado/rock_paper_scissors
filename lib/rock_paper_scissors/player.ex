defmodule RockPaperScissors.Player do
  @derive Jason.Encoder
  defstruct [
    id: nil, 
    name: :none
  ]
end
