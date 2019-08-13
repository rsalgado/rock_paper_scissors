defmodule RockPaperScissorsWeb.GameController do
  use RockPaperScissorsWeb, :controller

  import Routes
  alias RockPaperScissors.GameServer
  alias RockPaperScissorsWeb.ErrorView

  plug :authorize_user

  # Override default action plug to inject the player into the controller's actions
  def action(conn, _opts) do
    player = get_session(conn, :current_user)
    args = [conn, conn.params, player]
    apply(__MODULE__, action_name(conn), args)
  end

  @doc """
  Main action for showing forms where user will create a new game or join an existing one
  """
  def new(conn, _params, player) do
    render(conn, "new.html", user_name: player.name)
  end

  @doc """
  Create a new game with the current user as host
  """
  def create(conn, _params, player) do
    game_name = RockPaperScissors.random_alphanumeric(10)

    case RockPaperScissors.new_game(game_name) do
      {:ok, game} ->
        GameServer.set_host(game, player)
        conn
        |> put_flash(:info, "Game #{game_name} created correctly")
        |> redirect(to: Routes.game_path(conn, :show, game_name))
        |> halt()

      {:error, reason} ->
        conn
        |> put_flash(:error, reason)
        |> render("new.html", user_name: player.name)
    end
  end

  @doc """
  Show a game, only if current user is a player (guest or host)
  """
  def show(conn, %{"id" => game_name}, player) do
    game = RockPaperScissors.find_game(game_name)

    if game && game_player?(game, player) do
      render(conn, "show.html", game_name: game_name, user_name: player.name)
    else
      conn
      |> put_view(ErrorView)
      |> render("401.html")
    end
  end

  # Check whether the current user is a player/member of the game
  defp game_player?(game, player) do
    GameServer.player_role(game, player) in [:guest, :host]
  end

  @doc """
  Join an existing game as guest
  """
  def join(conn, %{"game" => %{"name" => game_name}}, player) do
    game = RockPaperScissors.find_game(game_name)

    if game do
      if GameServer.status(game) == :missing_guest do
        GameServer.set_guest(game, player)
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

  # Plug for user authorization
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
