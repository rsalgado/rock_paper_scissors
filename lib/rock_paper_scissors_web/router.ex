defmodule RockPaperScissorsWeb.Router do
  use RockPaperScissorsWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_user_token
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", RockPaperScissorsWeb do
    pipe_through :browser

    get "/", GameController, :new

    resources "/games", GameController, only: [:new, :create, :show]
    post "/games/join", GameController, :join, as: :game

    resources "/sessions", SessionController, only: [:new, :create, :delete], singleton: true
  end

  # Other scopes may use custom stacks.
  # scope "/api", RockPaperScissorsWeb do
  #   pipe_through :api
  # end

  defp put_user_token(conn, _opts) do
    if current_user = get_session(conn, :current_user) do
      token = Phoenix.Token.sign(conn, "user socket", current_user)
      assign(conn, :user_token, token)
    else
      conn
    end
  end
end
