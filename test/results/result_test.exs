defmodule BlastTest.Result do
  use ExUnit.Case
  alias Blast.Result

  @url "https://api.test/path"
  @responses %{
    ok: %HTTPoison.Response{
      request_url: @url,
      status_code: 200
    },
    not_found: %HTTPoison.Response{
      request_url: @url,
      status_code: 404
    },
    forbidden: %HTTPoison.Response{
      request_url: @url <> "/admin",
      status_code: 403
    }
  }

  describe "add_response should" do
    test "add initial response" do
      result = Result.add_response(%Result{}, @responses.ok)
      %{200 => 1} = result.responses[@url]
    end

    test "increment status field for url" do
      result =
        %Result{}
        |> Result.add_response(@responses.ok)
        |> Result.add_response(@responses.ok)
        |> Result.add_response(@responses.ok)

      %{200 => 3} = result.responses[@url]
    end

    test "handle different statuses" do
      result =
        %Result{}
        |> Result.add_response(@responses.ok)
        |> Result.add_response(@responses.not_found)

      %{200 => 1, 404 => 1} = result.responses[@url]
    end

    test "handle multiple urls" do
      result =
        %Result{}
        |> Result.add_response(@responses.ok)
        |> Result.add_response(@responses.not_found)
        |> Result.add_response(@responses.forbidden)

      %{200 => 1, 404 => 1} = result.responses[@url]
      %{403 => 1} = result.responses[@url <> "/admin"]
    end
  end
end
