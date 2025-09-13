defmodule Blast.Config.Test do
  use ExUnit.Case
  alias Blast.Config

  describe("valid module") do
    test("should return config when loaded") do
      # Act
      {:ok, config} = Config.load(ConfigTest.Valid)

      # Assert
      expected_base_url = ConfigTest.Valid.base_url()
      assert config.base_url === expected_base_url
      assert length(config.requests) == 2

      get = Enum.find(config.requests, &(&1.method == :get))
      post = Enum.find(config.requests, &(&1.method == :post))
      assert get.method == :get
      assert get.url == "#{expected_base_url}/facts"
      assert map_size(get.headers) == 1

      assert post.method == :post
      assert post.url == "#{expected_base_url}/cats"
      assert map_size(post.headers) == 2
    end
  end

  describe("invalid config") do
    test("missing required callbacks") do
      {:error, err} = Config.load(ConfigTest.MissingRequired)
      assert err
    end

    test("empty requests") do
      {:error, err} = Config.load(ConfigTest.EmptyRequests)
      assert "requests must not be empty" =~ err
    end

    test("invalid base_url() type") do
      {:error, err} = Config.load(ConfigTest.InvalidBaseUrl)
      assert "unrecognizable return from base_url: 1234" === err
    end

    test("invalid body definition: body and body-file") do
      {:error, err} = Config.load(ConfigTest.InvalidBodys)
      assert err
    end
  end
end

defmodule ConfigTest.Valid do
  use Blastfile

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

defmodule ConfigTest.MissingRequired do
end

defmodule ConfigTest.EmptyRequests do
  def base_url(), do: "http://localhost:1234"

  def requests(), do: []
end

defmodule ConfigTest.InvalidBaseUrl do
  def base_url(), do: 1234

  def requests(), do: []
end

defmodule ConfigTest.InvalidBodys do
  def base_url(), do: "http://localhost:1234"

  def requests(),
    do: [%{method: "get", path: "/", body: "...", file: "./test/hooks_test.exs"}]
end
