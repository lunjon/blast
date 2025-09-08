alias Blast.Collector
alias Blast.Result

# Define function for starting blast locally.
# Make sure you're running an API on localhost:8080.
start_local = fn ->
  Blast.CLI.main(["-b", "examples/basic.ex"])
end
