defmodule RockPaperScissorsWeb.SessionController do
  @moduledoc """
  Phoenix controller for handling sessions: signing in and out.
  """

  use RockPaperScissorsWeb, :controller
  alias RockPaperScissors.Player

  @doc """
  Render the form for creating a new session (signing in)
  """
  def new(conn, _params) do
    render(conn, "new.html")
  end

  @doc """
  Create the session, adding the player as `:current_user`
  """
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

  @doc """
  Clear the data stored in the session
  """
  def delete(conn, _params) do
    conn
    |> delete_session(:current_user)
    |> put_flash(:info, "Goodbye!")
    |> redirect(to: "/")
    |> halt()
  end
end
