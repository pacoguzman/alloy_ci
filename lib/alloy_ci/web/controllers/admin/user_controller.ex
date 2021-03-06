defmodule AlloyCi.Web.Admin.UserController do
  use AlloyCi.Web, :admin_controller

  alias AlloyCi.{Accounts, User, Repo}

  # Make sure that we have a valid token in the :admin area of the session
  # We've aliased Guardian.Plug.EnsureAuthenticated in our AlloyCi.Web.admin_controller macro
  plug EnsureAuthenticated, handler: __MODULE__, key: :admin

  def index(conn, params, current_user, _claims) do
    {users, kerosene} = User |> Repo.paginate(params)
    render conn, "index.html", kerosene: kerosene, users: users, current_user: current_user
  end

  def delete(conn, %{"id" => id}, _, _) do
    {:ok, _} = Accounts.delete_user(id)
    conn
    |> put_flash(:info, "User was deleted successfully")
    |> redirect(to: admin_user_path(conn, :index))
  end

  def unauthenticated(conn, _params) do
    conn
    |> put_flash(:error, "Admin authentication required")
    |> redirect(to: admin_login_path(conn, :new))
  end
end
