defmodule RockPaperScissorsWeb.PageController do
  use RockPaperScissorsWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
