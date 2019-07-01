defmodule RockPaperScissorsWeb.SessionController do
  use RockPaperScissorsWeb, :controller

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"user" => user}) do
    return_path = get_session(conn, :return_to)
    user_name = user["name"]

    conn
    |> delete_session(:return_to)
    |> put_session(:current_user, user_name)
    |> put_flash(:info, "Welcome #{user_name}")
    |> redirect(to: return_path)
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
