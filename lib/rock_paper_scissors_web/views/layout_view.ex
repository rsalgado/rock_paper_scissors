defmodule RockPaperScissorsWeb.LayoutView do
  use RockPaperScissorsWeb, :view
  import Routes, only: [session_path: 2]

  def logged_in?(conn) do
    conn.assigns[:user_name] != nil
  end
end
