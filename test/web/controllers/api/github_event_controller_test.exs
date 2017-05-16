defmodule AlloyCi.Web.Api.GithubEventControllerTest do
  @moduledoc """
  """
  use AlloyCi.Web.ConnCase
  alias AlloyCi.Pipeline
  import AlloyCi.Factory
  import Mock

  test "handles push events" do
    with_mock Tentacat.Contents, [find_in: fn(_, _, _, _, _) -> %{"contents" => "fake-data"} end] do
      project = insert(:project, repo_id: "14321")
      params = %{
        ref: "refs/heads/changes",
        before: "9049f1265b7d61be4a8904a9a27120d2064dab3b",
        after: "0d1a26e67d8f5eaf1f6ba5c57fc3c7d91ac0fd1c",
        repository: %{id: "14321"},
        head_commit: %{message: "Update README.md"},
        sender: %{
          login: "supernova32",
          avatar_url: "https://avatars0.githubusercontent.com/u/723365?v=3"
        },
        installation: %{id: "2030"}
      }
      conn =
        build_conn()
        |> put_req_header("x-github-event", "push")
        |> post("/api/github/handle_event", params)

      pipeline =
        Pipeline
        |> where(project_id: ^project.id)
        |> Repo.one

      assert conn.resp_body =~ "Pipeline with ID: #{pipeline.id} created sucessfully."
    end
  end

  test "when branch was deleted" do
    params = %{
      ref: "refs/heads/changes",
      before: "9049f1265b7d61be4a8904a9a27120d2064dab3b",
      after: "0000000000000000000000000000000000000000",
      repository: %{id: "14322"},
      head_commit: nil
    }

    conn =
      build_conn()
      |> put_req_header("x-github-event", "push")
      |> post("/api/github/handle_event", params)

    assert conn.resp_body =~ "deletion is not handled"
  end

  test "when commit message contains [skip ci]" do
    params = %{
      head_commit: %{message: "Test [skip ci]"}
    }

    conn =
      build_conn()
      |> put_req_header("x-github-event", "push")
      |> post("/api/github/handle_event", params)

    assert conn.resp_body =~ "Pipeline creation skipped"
  end

  test "when pipeline exists already" do
    with_mock Tentacat.Contents, [find_in: fn(_, _, _, _, _) -> %{"contents" => "fake-data"} end] do
      pipeline_params = %{
        ref: "refs/heads/changes",
        sha: "0d1a26e67d8f5eaf1f6ba5c57fc3c7d91ac0fd1c"
      }

      insert(:project, repo_id: "14322")
      |> with_pipeline(pipeline_params)

      params = %{
        ref: "refs/heads/changes",
        before: "9049f1265b7d61be4a8904a9a27120d2064dab3b",
        after: "0d1a26e67d8f5eaf1f6ba5c57fc3c7d91ac0fd1c",
        repository: %{id: "14322"},
        head_commit: %{message: "Update README.md"},
        sender: %{
          login: "supernova32",
          avatar_url: "https://avatars0.githubusercontent.com/u/723365?v=3"
        }
      }

      conn =
        build_conn()
        |> put_req_header("x-github-event", "push")
        |> post("/api/github/handle_event", params)

      assert conn.resp_body =~ "errors"
    end
  end

  test "handles all other events" do
    conn =
      build_conn()
      |> put_req_header("x-github-event", "pull_request")
      |> post("/api/github/handle_event", %{action: "some action", number: "1"})

    assert conn.resp_body =~ "Event pull_request is not handled by this endpoint."
  end
end
