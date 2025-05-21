defmodule Blast.CLI.Parser do
  @workers 2
  @frequency 10

  @help """
  blast - load test HTTP APIs

  Options:
    -s/--specfile      File path to blast file.
                       (default: looks for blast.y[a]ml in current working directory)
    --hooks FILE       Load an elixir file (.ex) as hooks module.
    -w/--workers N     Number of concurrent workers to run. This option is only viable
                       when no control has been configured in the settings in the spec.
                       (default: #{@workers})
    -f/--frequency N   Sets the frequency of requests (req/s) per worker. 
                       This will override any value configured in the settings in the spec.
                       A value of 0 means no limit. (default: #{@frequency})
    --help             Display this help message.
  """

  def parse_args(args) do
    OptionParser.parse(args,
      strict: [
        specfile: :string,
        workers: :integer,
        frequency: :integer,
        duration: :integer,
        hooks: :string,
        repl: :boolean,
        help: :boolean
      ],
      aliases: [
        s: :specfile,
        w: :workers,
        f: :frequency,
        h: :help
      ]
    )
    |> handle_parsed_args()
  end

  defp handle_parsed_args({args, [], []}) do
    if Keyword.get(args, :help) do
      {:help, @help}
    else
      with {:ok, spec} <- parse_specfile(Keyword.get(args, :specfile)),
           {:ok, hook_file} <- parse_hook_file(Keyword.get(args, :hooks)) do
        args = %{
          spec: spec,
          hook_file: hook_file,
          workers: Keyword.get(args, :workers, @workers),
          frequency: Keyword.get(args, :frequency, 10),
          repl: Keyword.get(args, :repl, false)
        }

        {:ok, args}
      else
        err -> err
      end
    end
  end

  defp handle_parsed_args({_, _rest_args, invalid_args}) do
    invalid =
      invalid_args
      |> Enum.map(fn {arg, _} -> arg end)
      |> Enum.join(", ")

    {:error, "invalid arguments: #{invalid}"}
  end

  defp parse_specfile(nil) do
    cond do
      File.exists?("./blast.yaml") -> parse_specfile("./blast.yaml")
      File.exists?("./blast.yml") -> parse_specfile("./blast.yml")
      File.exists?("./test/blast.yml") -> parse_specfile("./test/blast.yml")
      true -> {:error, "spec file not found"}
    end
  end

  defp parse_specfile(filepath) when is_binary(filepath), do: Blast.Spec.load_file(filepath)

  defp parse_hook_file(nil), do: {:ok, nil}

  defp parse_hook_file(filepath) do
    case File.exists?(filepath) do
      false -> {:error, "file not found: #{filepath}"}
      true -> {:ok, filepath}
    end
  end
end
