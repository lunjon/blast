alias Blast.Orchestrator

# Spawn in a new process since `main` hangs the process.
spawn(fn ->
  Blast.CLI.main(["--blastfile", "examples/basic.ex", "-f", "10", "-w", "5"])
end)

start_blast = fn ->
  Process.sleep(50)
  Orchestrator.start()
end

stop_blast = fn ->
  Orchestrator.stop()
end

IO.puts("
=== Blast ===
Use start_blast.() or stop_blast.() to start or stop.
")
