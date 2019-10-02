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


  describe "GET /games/:id" do
    test "Trying to show a game that does not exist", %{conn: conn} do
      player = %Player{name: "Alice", id: "abc123"}
      conn = conn
              |> assign(:current_user, player)
              |> get("/games/inV4L1D")

      assert html_response(conn, 401) =~ "Unauthorized"
    end

    test "Trying to show a game when not a player", %{conn: conn} do
      name = RockPaperScissors.random_alphanumeric()
      {:ok, _game} = RockPaperScissors.new_game(name)
      player = %Player{name: "Alice", id: "abc123"}
      conn = conn
              |> assign(:current_user, player)
              |> get("/games/#{name}")

      assert html_response(conn, 401) =~ "Unauthorized"
    end

    test "Showing a game when a player", %{conn: conn} do
      name = RockPaperScissors.random_alphanumeric()
      {:ok, game_pid} = RockPaperScissors.new_game(name)
      player = %Player{name: "Alice", id: "abc123"}
      GameServer.set_host(game_pid, player)
      conn = conn
              |> assign(:current_user, player)
              |> get("/games/#{name}")

      assert html_response(conn, 200) =~ ~s(<div data-game-name="#{name}" id="game">)
      assert conn.resp_body =~ ~s(<h2>Game <span class="game-name">{{name}}</span></h2>)
    end
  end

  describe "POST /games/join/" do
    test "Try to join an invalid game", %{conn: conn} do
      player = %Player{name: "Alice", id: "abc123"}
      conn = conn
              |> assign(:current_user, player)
              |> post("/games/join", %{"game" => %{"name" => "inV4L1D"}})

      assert html_response(conn, 404) =~ "Not Found"
    end

    test "Try to join a full game", %{conn: conn} do
      name = RockPaperScissors.random_alphanumeric()
      {:ok, game_pid} = RockPaperScissors.new_game(name)

      GameServer.set_host(game_pid, %Player{name: "Alice", id: "abc123"})
      GameServer.set_guest(game_pid, %Player{name: "Bob", id: "def456"})

      player = %Player{name: "Charlie", id: "ghi789"}
      conn = conn
              |> assign(:current_user, player)
              |> post("/games/join", %{"game" => %{"name" => name}})

      assert redirected_to(conn, 302) =~ "/"
      assert get_flash(conn, :error) == "Can't join game #{name} as guest"
    end

    test "Join a valid game as guest", %{conn: conn} do
      name = RockPaperScissors.random_alphanumeric()
      {:ok, game_pid} = RockPaperScissors.new_game(name)
      GameServer.set_host(game_pid, %Player{name: "Alice", id: "abc123"})

      player = %Player{name: "Bob", id: "def456"}
      conn = conn
              |> assign(:current_user, player)
              |> post("/games/join", %{"game" => %{"name" => name}})

      assert redirected_to(conn, 302) =~ "/games/#{name}"
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
