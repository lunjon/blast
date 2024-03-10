# This script is used when start blast using "mix run".
#
# Usage: mix run main.exs [ARGS]

Blast.CLI.main(System.argv())

Process.sleep(:infinity)
