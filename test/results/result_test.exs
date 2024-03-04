defmodule BlastTest.Result do
  use ExUnit.Case
  alias Blast.Result

  @url "https://api.test/path"
  @responses %{
    ok: %HTTPoison.Response{
      request_url: @url,
      request: %{method: :get},
      status_code: 200
    },
    not_found: %HTTPoison.Response{
      request_url: @url,
      request: %{method: :get},
      status_code: 404
    },
    forbidden: %HTTPoison.Response{
      request_url: @url <> "/admin",
      request: %{method: :get},
      status_code: 403
    }
  }

  describe "add_response should" do
    test "add initial response" do
      result = Result.add_response(%Result{}, 5, @responses.ok)
      %{200 => 1} = result.responses["GET #{@url}"]
    end

    test "increment status field for url" do
      result =
        %Result{}
        |> Result.add_response(1, @responses.ok)
        |> Result.add_response(2, @responses.ok)
        |> Result.add_response(3, @responses.ok)

      %{200 => 3} = result.responses["GET #{@url}"]
    end

    test "handle different statuses" do
      result =
        %Result{}
        |> Result.add_response(25, @responses.ok)
        |> Result.add_response(25, @responses.not_found)

      %{200 => 1, 404 => 1} = result.responses["GET #{@url}"]
    end

    test "handle multiple urls" do
      result =
        %Result{}
        |> Result.add_response(12, @responses.ok)
        |> Result.add_response(12, @responses.not_found)
        |> Result.add_response(12, @responses.forbidden)

      %{200 => 1, 404 => 1} = result.responses["GET #{@url}"]
      %{403 => 1} = result.responses["GET " <> @url <> "/admin"]
    end
  end
end
