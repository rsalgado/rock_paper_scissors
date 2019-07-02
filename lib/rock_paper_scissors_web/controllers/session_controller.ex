defmodule RockPaperScissorsWeb.SessionController do
  use RockPaperScissorsWeb, :controller
  alias RockPaperScissors.Player

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"user" => user}) do
    return_path = get_session(conn, :return_to)
    player = %Player{
      name: user["name"],
      id: RockPaperScissors.random_alphanumeric()
    }

    conn
    |> delete_session(:return_to)
    |> put_session(:current_user, player)
    |> put_flash(:info, "Welcome #{player.name}")
    |> redirect(to: return_path || "/")
    |> halt()
  end

  def delete(conn, _params) do
    conn
    |> delete_session(:current_user)
    |> put_flash(:info, "Goodbye!")
    |> redirect(to: "/")
    |> halt()
  end
end
