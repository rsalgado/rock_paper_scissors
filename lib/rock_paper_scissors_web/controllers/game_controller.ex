defmodule RockPaperScissorsWeb.GameController do
  use RockPaperScissorsWeb, :controller

  import Routes
  alias RockPaperScissors.GameServer
  alias RockPaperScissorsWeb.ErrorView

  plug :authorize_user


  def new(conn, _params) do
    user_name = get_session(conn, :current_user)
    render(conn, "new.html", user_name: user_name)
  end

  def create(conn, %{"game" => game}) do
    user_name = get_session(conn, :current_user)
    game_name = game["name"]

    case RockPaperScissors.new_game(game_name) do
      {:ok, game} ->
        GameServer.set_host(game, user_name)
        conn
        |> put_flash(:info, "Game #{game_name} created correctly")
        |> redirect(to: Routes.game_path(conn, :show, game_name))
        |> halt()

      {:error, reason} ->
        conn
        |> put_flash(:error, reason)
        |> render("new.html", user_name: user_name)
    end
  end

  def show(conn, %{"id" => game_name}) do
    game = RockPaperScissors.find_game(game_name)

    if game do
      state = GameServer.state(game)
      json(conn, state)
    else
      conn
      |> put_view(ErrorView)
      |> render("404.html")
    end
  end

  def join(conn, %{"id" => game_name}) do
    user_name = get_session(conn, :current_user)
    game = RockPaperScissors.find_game(game_name)

    if game do
      if GameServer.status(game) == :missing_guest do
        GameServer.set_guest(game, user_name)
        conn
        |> redirect(to: game_path(conn, :show, game_name))
        |> halt()

      else
        conn
        |> put_flash(:error, "Can't join game #{game_name} as guest")
        |> redirect(to: "/")
        |> halt()
      end

    else
      conn
      |> put_view(ErrorView)
      |> render("404.html")
    end
  end


  defp authorize_user(conn, _opts) do
    if get_session(conn, :current_user) do
      conn
    else
      conn
      |> put_session(:return_to, conn.request_path)
      |> redirect(to: session_path(conn, :new))
      |> halt()
    end
  end
end
