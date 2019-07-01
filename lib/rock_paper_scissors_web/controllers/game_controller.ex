defmodule RockPaperScissorsWeb.GameController do
  use RockPaperScissorsWeb, :controller
  import Routes, only: [session_path: 2]


  plug :authorize_user


  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, _params) do
    text(conn, "Not implemented yet")
  end

  def show(conn, _params) do
    text(conn, "Not implemented yet")
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
