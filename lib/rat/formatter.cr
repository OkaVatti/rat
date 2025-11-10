require "../internals/highlighter"

module Rat
  module Formatter
    def self.print_header_if_needed(path : String, interactive : Bool, plain : Bool)
      return unless interactive && !plain

      stat = begin File.info(path) rescue nil end

      if stat
        STDOUT.puts "\e[1;34m==> #{path}\e[0m  (\e[33m#{stat.size} bytes\e[0m, \e[32m#{stat.modification_time}\e[0m)"
      else
        STDOUT.puts "==> #{path}"
      end
    end

    def self.format_line(line : String, path : String, line_num : Int32 = 0, line_numbers : Bool = false, plain : Bool = false, first_line : String = "")
      content = plain ? line : Highlighter.highlight(line, path, first_line)

      if line_numbers && line_num > 0
        "%6d  %s\n" % {line_num, content}
      else
        "#{content}\n"
      end
    end
  end
end
