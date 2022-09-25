defmodule CoreTest.Result do
  use ExUnit.Case
  alias Core.Result

  @url "https://api.test/path"
  @responses %{
    ok: %HTTPoison.Response{
      request_url: @url,
      status_code: 200
    },
    not_found: %HTTPoison.Response{
      request_url: @url,
      status_code: 404
    }
  }

  test "add response - initial" do
    result = Result.add_response(%Result{}, @responses.ok)
    %{200 => 1} = result.responses[@url]
  end

  test "add response - multiple" do
    result =
      %Result{}
      |> Result.add_response(@responses.ok)
      |> Result.add_response(@responses.ok)
      |> Result.add_response(@responses.ok)

    %{200 => 3} = result.responses[@url]
  end

  test "add response - different statuses" do
    result =
      %Result{}
      |> Result.add_response(@responses.ok)
      |> Result.add_response(@responses.not_found)

    %{200 => 1, 404 => 1} = result.responses[@url]
  end
end
