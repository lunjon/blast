# This script is used when start blast using "mix run".
#
# Usage: mix run blast.exs [ARGS]
#
# Use --help for getting help.

Blast.CLI.main(System.argv())
Process.sleep(:infinity)
