defmodule RockPaperScissors.GameStateTest do
  use ExUnit.Case, async: true
  alias RockPaperScissors.GameState
  alias RockPaperScissors.Player

  test "set_host/2: Setting a valid host" do
    state = %GameState{}
    player = %Player{id: "1234", name: "John Doe"}
    assert state.status == :missing_players

    new_state = GameState.set_host(state, player)
    assert new_state.players.host == player
    assert new_state.status == :missing_guest
  end

  test "set_guest/2: Setting a valid guest" do
    state = %GameState{}
    player = %Player{id: "1234", name: "Jane Doe"}
    assert state.status == :missing_players

    new_state = GameState.set_guest(state, player)
    assert new_state.players.guest == player
    assert new_state.status == :missing_host
  end

  test "set_choice/3: Setting valid choices" do
    host = %Player{name: "Homer"}
    guest = %Player{name: "Gavin"}
    state =
      %GameState{}
      |> GameState.set_host(host)
      |> GameState.set_guest(guest)

    assert state.choices.host == :none
    assert state.choices.guest == :none
    assert state.status == :waiting_choices

    new_state = GameState.set_choice(state, :host, :rock)
    assert new_state.choices.host == :rock
    assert new_state.status == :waiting_guest_choice

    new_state = GameState.set_choice(state, :guest, :paper)
    assert new_state.choices.guest == :paper
    assert new_state.status == :waiting_host_choice

    new_state =
      state
      |> GameState.set_choice(:host, :paper)
      |> GameState.set_choice(:guest, :scissors)
    assert new_state.status == :finished
  end

  describe "Game rules" do
    setup do
      state =
        %GameState{}
        |> GameState.set_host(%Player{name: "Homer"})
        |> GameState.set_guest(%Player{name: "Gavin"})
      {:ok, state: state}
    end

    test "rock & paper", %{state: state} do
      new_state = set_choices(state, :rock, :paper)
      assert new_state.winner == :guest

      new_state = set_choices(state, :paper, :rock)
      assert new_state.winner == :host
    end

    test "paper & scissors", %{state: state} do
      new_state = set_choices(state, :paper, :scissors)
      assert new_state.winner == :guest

      new_state = set_choices(state, :scissors, :paper)
      assert new_state.winner == :host
    end

    test "scissors & rock", %{state: state} do
      new_state = set_choices(state, :scissors, :rock)
      assert new_state.winner == :guest

      new_state = set_choices(state, :rock, :scissors)
      assert new_state.winner == :host
    end

    test "ties", %{state: state} do
      new_state = set_choices(state, :rock, :rock)
      assert new_state.winner == :tie

      new_state = set_choices(state, :paper, :paper)
      assert new_state.winner == :tie

      new_state = set_choices(state, :scissors, :scissors)
      assert new_state.winner == :tie
    end
  end

  defp set_choices(state, host_choice, guest_choice) do
    state
    |> GameState.set_choice(:host, host_choice)
    |> GameState.set_choice(:guest, guest_choice)
  end
end
