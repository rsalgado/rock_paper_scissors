defmodule RockPaperScissorsWeb.SessionController do
  use RockPaperScissorsWeb, :controller

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, _params) do
    text(conn, "Not implemented yet")
  end

  def delete(conn, _params) do
    text(conn, "Not implemented yet")
  end
end
