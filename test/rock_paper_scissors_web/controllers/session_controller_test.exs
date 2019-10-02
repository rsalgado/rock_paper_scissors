defmodule RockPaperScissorsWeb.SessionControllerTest do
  use RockPaperScissorsWeb.ConnCase


  setup %{} do
    # TODO: Find a better and less brittle way to deal with these situations
    # See: `game_controller_test.exs` file for more details
    Application.ensure_started(:rock_paper_scissors)
  end

  test "GET /sessions/new", %{conn: conn} do
    conn = get(conn, "/sessions/new")
    assert html_response(conn, 200) =~ "Please enter your name to continue"
  end

  test "POST /sessions", %{conn: conn} do
    name = "Alice"
    conn = post(conn, "/sessions", %{"user" => %{"name" => name}})

    assert redirected_to(conn, 302) == "/"
    assert get_flash(conn, :info) == "Welcome #{name}"
    assert get_session(conn, :current_user).name == "Alice"
  end

  test "DELETE /sessions", %{conn: conn} do
    name = "Alice"
    conn =
      conn
      |> post("/sessions", %{"user" => %{"name" => name}})
      |> delete("/sessions")

    assert redirected_to(conn, 302) == "/"
    assert get_flash(conn, :info) == "Goodbye!"
    assert get_session(conn, :current_user) == nil
  end
end
