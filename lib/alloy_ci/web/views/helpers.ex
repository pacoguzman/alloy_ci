defmodule AlloyCi.Web.ViewHelpers do
  @moduledoc """
  """
  use Phoenix.HTML
  import AlloyCi.Web.Router.Helpers

  @github_api Application.get_env(:alloy_ci, :github_api)

  def active_on_current(%{request_path: path}, path), do: "active"
  def active_on_current(_, _), do: ""

  def admin_logged_in?(conn), do: Guardian.Plug.authenticated?(conn, :admin)
  def admin_user(conn), do: Guardian.Plug.current_resource(conn, :admin)

  def callout("success"), do: "callout-success"
  def callout("failed"), do: "callout-danger"
  def callout("running"), do: "callout-warning"
  def callout(_), do: "callout-general"

  def card_status("success"), do: "card-inverse card-success"
  def card_status("failed"), do: "card-inverse card-danger"
  def card_status("running"), do: "card-inverse card-primary"
  def card_status("pending"), do: "card-inverse card-info"
  def card_status(_), do: ""

  def clean_branch(branch), do: branch |> String.replace("refs/heads/", "")

  def current_user(conn), do: Guardian.Plug.current_resource(conn)

  def duration(nil), do: "Pending"
  def duration(seconds), do: seconds |> TimeConvert.to_compound

  def fork_icon(fork) do
    if fork do
      icon("code-fork")
    else
      icon("archive")
    end
  end

  def icon(name) do
    {:safe, "<i class='fa fa-#{name}'></i>"}
  end

  def icon("identity", classes), do: icon("vcard", classes)

  def icon(name, classes) do
    {:safe, "<i class='fa fa-#{name} #{classes}'></i>"}
  end

  def logged_in?(conn), do: Guardian.Plug.authenticated?(conn)

  def notification_text(%{notification_type: "pipeline_failed"} = notification) do
    [
      content_tag(:p) do
        [
          base_notification_text(notification),
          " has failed. You can view the full trace log of the pipeline ",
          link_to_pipeline(notification)
        ]
      end,
      commit_message(notification)
    ]

  end

  def notification_text(%{notification_type: "pipeline_succeeded"} = notification) do
    [
      content_tag(:p) do
        [
          base_notification_text(notification),
          " has finished correctly. You can view the full trace log of the pipeline ",
          link_to_pipeline(notification)
        ]
      end,
      commit_message(notification)
    ]
  end

  def pretty_commit(msg) do
    msg |> String.split("\n") |> List.first
  end

  def pretty_date(date) do
    date
    |> Timex.to_datetime
    |> Timex.format!("%Y-%m-%d %H:%M %Z", :strftime)
  end

  def privacy_icon(private) do
    if private do
      icon("lock")
    else
      icon("unlock")
    end
  end

  def render_flash(conn, type) do
    flash = Phoenix.Controller.get_flash(conn, type)
    if flash do
      [content_tag :button, class: "close", data: [dismiss: "alert"] do
        content_tag :span, "✖"
      end, flash]
    end
  end

  def repo_icon("User"), do: icon("user")
  def repo_icon("Organization"), do: icon("users")

  def server_url do
    Application.get_env(:alloy_ci, :server_url)
  end

  def sha_link(pipeline) do
    content_tag(:a, href: @github_api.sha_url(pipeline.project, pipeline)) do
      pipeline.sha |> String.slice(0..7)
    end
  end

  def sha_link(pipeline, project) do
    content_tag(:a, href: @github_api.sha_url(project, pipeline)) do
      pipeline.sha |> String.slice(0..7)
    end
  end

  def status_btn("success"), do: "btn-success"
  def status_btn("failed"), do: "btn-danger"
  def status_btn("running"), do: "btn-warning"
  def status_btn(_), do: "btn-outline-secondary active"

  def status_icon("created"), do: icon("calendar")
  def status_icon("failed"),  do: icon("close")
  def status_icon("pending"), do: icon("circle-o-notch")
  def status_icon("running"), do: icon("circle-o-notch", "fa-spin")
  def status_icon("success"), do: icon("check")
  def status_icon(_), do: icon("ban")

  ###################
  # Private functions
  ###################
  defp base_notification_text(notification) do
    [
      "The pipeline with ID: #{notification.content["pipeline"]["id"]} for the branch ",
      content_tag(:b, clean_branch(notification.content["pipeline"]["ref"]))
    ]
  end

  defp link_to_pipeline(notification) do
    link(
      "here.", to: project_pipeline_url(AlloyCi.Web.Endpoint, :show,
      notification.project_id, notification.content["pipeline"]["id"])
    )
  end

  defp commit_message(notification) do
    content_tag(:p) do
      [
        content_tag(:b, "Commit message: "),
        notification.content["pipeline"]["commit"]["message"]
      ]
    end
  end
end
