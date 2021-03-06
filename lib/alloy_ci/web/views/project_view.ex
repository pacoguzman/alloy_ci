defmodule AlloyCi.Web.ProjectView do
  use AlloyCi.Web, :view
  alias AlloyCi.{Accounts, Projects}
  import Kerosene.HTML

  def builds_chart(project) do
    project
    |> Chartable.builds_chart
    |> Poison.encode!
  end

  def has_github_auth(user) do
    case Accounts.github_auth(user) do
      nil -> false
      _ -> true
    end
  end

  def app_url do
    Application.get_env(:alloy_ci, :app_url)
  end
end
