defmodule Blast do
  use Blastfile

  def base_url(), do: "http://localhost:8080"

  def requests() do
    [
      %{
        method: "post",
        path: "/setup",
        # The most basic body is a string.
        body: "hello!"
      },
      %{
        method: "post",
        path: "/explosions",
        # If `body` is specified as a list or map,
        # blast will try to serialize into JSON.
        # It will also set the Content-Type header automatically.
        body: %{
          message: "Hello, fellow blasters!"
        }
      },
      %{
        method: "post",
        path: "/bad-forms",
        # By using `form` blast will send it as a POST form.
        # The value must be a list of two-element tuples,
        # just like `headers`.
        form: [
          {"username", "007"}
        ]
      },
      %{
        method: "post",
        path: "/from-file",
        # The `file` attribute allows one to specify
        # a local file to read as body.
        # Same could be Achieved by using the `body` attribute
        # along with the built-in File.read! function.
        file: "/path/to/file"
        # Same result:
        # file: File.read!("/path/to/file")
      }
    ]
  end
end
