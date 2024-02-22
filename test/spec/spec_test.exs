defmodule Blast.Spec.Test do
  use ExUnit.Case
  alias Blast.Spec

  @cats_base_url "https://cats.meow"
  @dogs_base_url "https://dogs.voff"

  describe("valid spec") do
    test("single endpoint") do
      # Act
      {:ok, spec} =
        Spec.load_string("""
        endpoints:
          - base-url: https://cats.meow
            requests:
              - path: /facts
              - method: post
                path: /cats
        """)

      # Assert
      %Spec{endpoints: [endpoint]} = spec
      assert endpoint.base_url === @cats_base_url

      [get, post] = endpoint.requests
      assert get.method == :get
      assert get.url == "#{@cats_base_url}/facts"
      assert post.method == :post
      assert post.url == "#{@cats_base_url}/cats"
    end

    test("two endpoints, one with headers") do
      # Act
      {:ok, spec} =
        Spec.load_string("""
        endpoints:
          - base-url: #{@cats_base_url}
            requests:
              - path: /facts
          - base-url: #{@dogs_base_url}
            default-headers:
              - name: "X-Blast"
                value: "4ever"
            requests:
              - path: /voffy
              - method: post
                path: /dogs
                body: '{"test": true}'
                headers:
                  - name: Authorization
                    value: Bearer test
        """)

      # Assert
      %Spec{endpoints: [cats_endpoint, dogs_endpoint]} = spec
      assert cats_endpoint.base_url === @cats_base_url

      [get] = cats_endpoint.requests
      assert get.method == :get
      assert get.url == "#{@cats_base_url}/facts"
      assert get.headers == %{}

      [_, post] = dogs_endpoint.requests
      assert post.method == :post
      assert post.url == "#{@dogs_base_url}/dogs"
      assert post.headers == %{"Authorization" => "Bearer test", "X-Blast" => "4ever"}

      requests = Spec.get_requests(spec)
      assert length(requests) == 3
    end
  end

  describe("invalid spec") do
    test("empty string") do
      {:error, _} = Spec.load_string("")
    end

    test("empty endpoints") do
      {:error, _} =
        Spec.load_string("""
        endpoints: []
        """)
    end

    test("empty endpoint requests") do
      {:error, _} =
        Spec.load_string("""
        endpoints:
          - base-url: https://example.com
            requests: []
        """)
    end

    test("invalid method") do
      {:error, _} =
        Spec.load_string("""
        endpoints:
          - base-url: https://example.com
            requests:
              - method: meow
                path: /test
        """)
    end

    test("missing base url") do
      {:error, _} =
        Spec.load_string("""
        endpoints:
          - requests:
              - path: /test
        """)
    end

    test("invalid body definition: body and body-file") do
      {:error, _} =
        Spec.load_string("""
        endpoints:
          - base-url: http://localhost
              - path: /test
                body: A string
                body-file: ./filepath.json
        """)
    end

    test("invalid body definition: body and body-form") do
      {:error, _} =
        Spec.load_string("""
        endpoints:
          - base-url: http://localhost
              - path: /test
                body: A string
                body-form:
                  - name: test
                    value: blast
        """)
    end
  end
end
