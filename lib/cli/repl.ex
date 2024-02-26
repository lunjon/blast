defmodule Blast.CLI.REPL do
  alias Blast.CLI.Output
  alias Blast.Manager
  alias Blast.Bucket
  alias Blast.Worker.Config

  @exit ["exit", "quit"]

  def start() do
    welcome()
    loop()
  end

  defp loop() do
    try do
      read_line() |> handle()
    rescue
      err -> Output.error("unhandled error: #{inspect(err)}")
    end

    loop()
  end

  # Parsing and handling
  # ====================

  defp handle([]), do: :ok

  defp handle(["status"]) do
    Bucket.get()
    |> Output.result()
  end

  defp handle(["start"]) do
    case Manager.kickoff() do
      {:error, reason} -> Output.error(reason)
      :ok -> IO.puts("Started")
    end
  end

  defp handle(["stop"]) do
    Manager.stop_all()
  end

  defp handle(["set", "frequency", value]) do
    case Integer.parse(value) do
      :error -> Output.error("invalid frequency: #{value}")
      {f, ""} -> set_config(:frequency, f)
    end
  end

  defp handle(["set", "workers", value]) do
    case Integer.parse(value) do
      :error -> Output.error("invalid value for workers: #{value}")
      {f, ""} -> set_config(:workers, f)
    end
  end

  defp handle(["set" | _]) do
    Output.error("unknown or invalid args for set")
  end

  defp handle(["config"]) do
    %Config{
      workers: workers,
      frequency: freq,
      requests: requests
    } = Manager.get_config()

    requests =
      requests
      |> Enum.uniq_by(fn req ->
        "#{req.method}-#{req.url}"
      end)
      |> Enum.map(fn req ->
        method =
          req.method
          |> to_string()
          |> String.upcase()
          |> String.pad_trailing(6)

        "  #{method} #{req.url}  "
      end)
      |> Enum.join("\n")

    IO.puts("""
    Workers:   #{workers}
    Frequency: #{freq}
    Requests:
    #{requests}
    """)
  end

  defp handle([cmd | args]) when cmd in @exit do
    case args do
      [] -> System.halt(0)
      _ -> Output.error("#{cmd} doesn't take any arguments")
    end
  end

  defp handle(["help"]) do
    IO.puts("""
    Commands:
      status              Show current status.
      set <name> <value>  Sets a configuration value, such as number of workers or frequency.
      help <cmd>          Show this help or help for a command
      quit                Quit the program. [alias: exit]
    """)
  end

  defp handle(["help", "status"]) do
    IO.puts("""
    Show current status.
    You can also see the status in the prompt.
    """)
  end

  defp handle(["help", "set"]) do
    IO.puts("""
    Sets number of workers or frequency.

      Set number of workers to 50:
        set workers 50

      Set frequency to 10:
        set freq[uency] 10
    """)
  end

  defp handle([cmd | _]) do
    Output.error("unknown command: #{cmd}")
  end

  defp set_config(key, value) do
    :ok =
      Manager.get_config()
      |> Map.update!(key, fn _ -> value end)
      |> Manager.set_config()
  end

  @spec read_line() :: [binary()]
  defp read_line() do
    status = Manager.get_status()
    prompt = "[#{status}]> "

    case IO.gets(prompt) do
      :eof -> ["exit"]
      {:error, _err} -> ["exit"]
      line -> String.trim(line) |> String.split()
    end
  end

  defp welcome() do
    IO.puts("""
    ___     _       ____    ____    ___ 
    |__]    |       |__|    [__      |  
    |__]    |___    |  |    ___]     |  
                                        

    Starting #{Output.green_italic("blast")}.
    """)
  end
end
