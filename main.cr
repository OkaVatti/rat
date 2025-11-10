# main.cr — entrypoint
require "./lib/rat/cli"

Rat::CLI.run(ARGV)
