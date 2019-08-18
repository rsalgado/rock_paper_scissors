defmodule RockPaperScissors.Player do
  @moduledoc """
  Struct for keeping player's data.
  """

  @derive Jason.Encoder
  defstruct [
    id: nil,
    name: :none
  ]
end
