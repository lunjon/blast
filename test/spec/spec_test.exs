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
        settings:
          frequency: 1
          control:
            kind: rampup
            properties:
              every: 5
              start: 1
              target: 10
              
        base-url: https://cats.meow
        requests:
          - path: /facts
          - method: post
            path: /cats
        """)

      # Assert
      assert spec.base_url === @cats_base_url
      assert length(spec.requests) == 2

      get = Enum.find(spec.requests, &(&1.method == :get))
      post = Enum.find(spec.requests, &(&1.method == :post))
      assert get.method == :get
      assert get.url == "#{@cats_base_url}/facts"
      assert post.method == :post
      assert post.url == "#{@cats_base_url}/cats"
    end

    test("two endpoints, one with headers") do
      # Act
      {:ok, spec} =
        Spec.load_string("""
        base-url: #{@dogs_base_url}
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

      post = Enum.find(spec.requests, &(&1.method == :post))
      assert post.method == :post
      assert post.url == "#{@dogs_base_url}/dogs"
      assert post.headers == %{"Authorization" => "Bearer test", "X-Blast" => "4ever"}
    end
  end

  describe("invalid spec") do
    test("empty string") do
      {:error, _} = Spec.load_string("")
    end

    test("empty requests") do
      {:error, _} =
        Spec.load_string("""
        base-url: "http://localhost"
        requests: []
        """)
    end

    test("invalid method") do
      {:error, _} =
        Spec.load_string("""
        base-url: https://example.com
        requests:
          - method: meow
            path: /test
        """)
    end

    test("missing base url") do
      {:error, _} =
        Spec.load_string("""
        requests:
          - path: /test
        """)
    end

    test("invalid body definition: body and body-file") do
      {:error, _} =
        Spec.load_string("""
        base-url: https://example.com
        requests:
          - path: /test
            body: A string
            body-file: ./filepath.json
        """)
    end

    test("invalid body definition: body and body-form") do
      {:error, _} =
        Spec.load_string("""
        base-url: http://localhost
        requests:
          - path: /test
            body: A string
            body-form:
              - name: test
                value: blast
        """)
    end

    test("invalid setting(control): unknown control kind") do
      {:error, _} =
        Spec.load_string("""
        settings:
          control:
            kind: hello

        base-url: http://localhost
        requests:
          - path: /test
        """)
    end

    test("invalid setting(control): rampup - missing properties") do
      {:error, _} =
        Spec.load_string("""
        settings:
          control:
            kind: rampup

        base-url: http://localhost
        requests:
          - path: /test
        """)
    end

    test("invalid setting(control): rampup - invalid field type") do
      {:error, _} =
        Spec.load_string("""
        settings:
          control:
            kind: rampup
            properties:
              every: "string"

        base-url: http://localhost
        requests:
          - path: /test
        """)
    end
  end
end
