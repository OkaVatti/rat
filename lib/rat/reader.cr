# lib/rat/reader.cr
require "file"

module Rat
  module Reader
    # Yields each line from path ("-" means stdin).
    # Block args: | line : String, line_num : Int32, first_line : String |
    def self.each_line(path : String, &)
      if path == "-"
        begin
          first_line = "" # track first line
          line_num = 0
          STDIN.each_line do |line|
            line_num += 1
            first_line = line if line_num == 1
            yield line, line_num, first_line
          end
        rescue ex
          STDERR.puts "rat: error reading stdin — #{ex.message}"
        end
      else
        begin
          File.open(path, "r") do |f|
            first_line = ""
            line_num = 0
            f.each_line do |line|
              line_num += 1
              first_line = line if line_num == 1
              yield line, line_num, first_line
            end
          end
        rescue ex
          STDERR.puts "rat: cannot open #{path} — #{ex.message}"
        end
      end
    end
  end
end
