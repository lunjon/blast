defmodule Blast.CLI.REPL do
  alias Blast.CLI.Output
  alias Core.Manager
  alias Core.Bucket
  alias Core.Worker.Config

  @exit ["exit", "quit"]

  def start() do
    # TODO: print welcome message
    loop()
  end

  defp loop() do
    read_line() |> handle()
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

  defp handle(["set" | args]) do
    IO.puts("set: #{inspect(args)}")
  end

  defp handle(["config"]) do
    %Config{
      workers: workers,
      request: request
    } = Manager.get_config()

    IO.puts("""
    URL:     #{request.url}
    Method:  #{request.method} 
    Workers: #{workers}
    """)
  end

  defp handle([cmd | args]) when cmd in @exit do
    case args do
      [] -> System.halt(0)
      _ -> Output.error("#{cmd} doesn't take any arguments")
    end
  end

  defp handle(["help" | _]) do
    IO.puts("""
    Commands:
      status              Show current status.
      set <name> <value>  Sets a configuration value.
                          This accept the same names as options when starting blast.
                          For instance, set URL with "set url <url>".
      help                Show this help.
      quit                Quit the program. [alias: exit]
    """)
  end

  defp handle([cmd | _]) do
    Output.error("unknown command: #{cmd}")
  end

  defp read_line() do
    status = Manager.get_status()
    prompt = "[#{status}] " <> Output.green("blast") <> "> "

    IO.gets(prompt)
    |> String.trim()
    |> String.split()
  end
end
