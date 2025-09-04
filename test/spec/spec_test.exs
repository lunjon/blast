defmodule BlastTest.Spec do
  use ExUnit.Case
  alias Blast.Spec

  describe("valid module") do
    test("should return spec when loaded") do
      # Act
      {:ok, spec} = Spec.load(Blast.SpecTest.Valid)

      # Assert
      expected_base_url = Blast.SpecTest.Valid.base_url()
      assert spec.base_url === expected_base_url
      assert length(spec.requests) == 2

      get = Enum.find(spec.requests, &(&1.method == :get))
      post = Enum.find(spec.requests, &(&1.method == :post))
      assert get.method == :get
      assert get.url == "#{expected_base_url}/facts"
      assert map_size(get.headers) == 1

      assert post.method == :post
      assert post.url == "#{expected_base_url}/cats"
      assert map_size(post.headers) == 2
    end
  end

  describe("invalid spec") do
    test("missing required callbacks") do
      {:error, err} = Spec.load(Blast.SpecTest.MissingRequired)
      assert err
    end

    test("empty requests") do
      {:error, err} = Spec.load(Blast.SpecTest.EmptyRequests)
      assert "requests must not be empty" =~ err
    end

    test("invalid base_url() type") do
      {:error, err} = Spec.load(Blast.SpecTest.InvalidBaseUrl)
      assert "unrecognizable return from base_url: 1234" === err
    end

    test("invalid body definition: body and body-file") do
      {:error, err} = Spec.load(Blast.SpecTest.InvalidBodys)
      assert err
    end
  end
end

defmodule Blast.SpecTest.Valid do
  def base_url(), do: "https://cats.meow"

  def requests() do
    [
      %{
        method: "get",
        path: "/facts"
      },
      %{
        method: "post",
        path: "/cats",
        headers: [{"Authorization", "Bearer test"}]
      }
    ]
  end

  def default_headers() do
    [
      {"Test", "true"}
    ]
  end
end

defmodule Blast.SpecTest.MissingRequired do
end

defmodule Blast.SpecTest.EmptyRequests do
  def base_url(), do: "http://localhost:1234"

  def requests(), do: []
end

defmodule Blast.SpecTest.InvalidBaseUrl do
  def base_url(), do: 1234

  def requests(), do: []
end

defmodule Blast.SpecTest.InvalidBodys do
  def base_url(), do: "http://localhost:1234"

  def requests(),
    do: [%{method: "get", path: "/", body: "...", file: "./test/hooks_test.exs"}]
end
