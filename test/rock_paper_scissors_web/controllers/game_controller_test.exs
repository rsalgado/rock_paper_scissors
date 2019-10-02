defmodule RockPaperScissorsWeb.GameControllerTest do
  use RockPaperScissorsWeb.ConnCase
  alias RockPaperScissors.{Player, GameServer}

  require IEx

  setup do
    # This will ensure that the application is started.
    # Otherwise it will fail, because rock_paper_scissors_test.exs stops it.
    # TODO: Find a better and less brittle way to deal with these situations
    Application.ensure_started(:rock_paper_scissors)
  end

  describe "GET /" do
    test "without a session it redirects to login page", %{conn: conn} do
      conn = get(conn, "/")
      assert redirected_to(conn, 302) =~ "/sessions/new"
    end

    test "with a session it loads the new game page", %{conn: conn} do
      player = %Player{name: "Alice", id: "abc123"}
      conn = conn
              |> assign(:current_user, player)
              |> get("/")

      assert html_response(conn, 200) =~ "<title>RockPaperScissors · Phoenix Framework</title>"
      assert conn.resp_body =~ "Alice"
      assert conn.resp_body =~ "Create Game"
      assert conn.resp_body =~ "Join Existing Game"
    end
  end

  test "POST /games/ - Create a valid game", %{conn: conn} do
    player = %Player{name: "Alice", id: "abc123"}
    conn = conn
            |> assign(:current_user, player)
            |> post("/games/", %{})

    "/games/"<>game_id = redirected_to(conn, 302)
    game_pid = RockPaperScissors.find_game(game_id)

    assert GameServer.player_role(game_pid, player) == :host
    assert get_flash(conn, :info) == "Game #{game_id} created correctly"
  end

end
