# rat.cr — minimal fresh rewrite (Crystal 1.18.2)
require "./internals/highlighter"

module Rat
  class CLI
    # Type declaration at class-level
    @lines_range : Tuple(Int32, Int32)?

    def self.run(argv : Array(String))
      new(argv).run
    end

    def initialize(argv : Array(String))
      @argv = argv.dup
      @files = [] of String
      @plain = false
      @line_numbers = false
      @lines_range = nil
      parse_args
    end

    def parse_args
      while @argv.any?
        arg = @argv.shift
        case arg
        when "--plain"
          @plain = true
        when "--number", "-n"
          @line_numbers = true
        when /\A--lines=(\d+)-(\d+)\z/
          start_i = $1.to_i32
          stop_i = $2.to_i32
          if start_i <= 0 || stop_i <= 0 || stop_i < start_i
            STDERR.puts "Invalid --lines range. Use 1-based START-END with START <= END"
            exit 1
          end
          @lines_range = {start_i, stop_i}
        when "-h", "--help"
          puts help
          exit 0
        else
          if arg.starts_with?("-")
            STDERR.puts "Unknown option: #{arg}"
            puts help
            exit 1
          else
            @files << arg
          end
        end
      end

      # default to stdin
      @files << "-" if @files.empty?
    end

    def help : String
      <<-HELP
        rat — simple file viewer (minimal, TTY friendly)

        Usage:
          rat [options] [files...]

        Options:
          --plain         Disable highlighting and headers
          --number, -n    Show line numbers
          --lines=START-END  Show only inclusive lines (1-based)
          -h, --help      Show this help

        If no files provided, reads from stdin (-).
      HELP
    end

    def run
      interactive = STDOUT.tty?
      @files.each_with_index do |path, idx|
        if path == "-"
          print_header_if_needed("<stdin>", interactive)
          content = begin
            STDIN.read_to_end
          rescue ex
            STDERR.puts "rat: error reading stdin — #{ex.message}"
            ""
          end
          output_content(content, "<stdin>", interactive)
        else
          print_header_if_needed(path, interactive)
          if !File.exists?(path)
            STDERR.puts "rat: cannot open #{path}: No such file"
            next
          end

          content = begin
            File.read(path)
          rescue ex
            STDERR.puts "rat: cannot open #{path} — #{ex.message}"
            next
          end

          output_content(content, path, interactive)
        end

        # blank line between files when interactive
        if interactive && idx < @files.size - 1
          puts "" unless @plain
        end
      end
    end

    private def print_header_if_needed(path : String, interactive : Bool)
      return unless interactive && !@plain
      stat = begin
        File.info(path)
      rescue
        nil
      end

      if stat
        size = stat.size
        mtime = stat.modification_time
        puts "\e[1;34m==> #{path}\e[0m  (\e[33m#{size} bytes\e[0m, \e[32m#{mtime}\e[0m)"
      else
        puts "==> #{path}"
      end
    end

    private def output_content(content : String, path : String, interactive : Bool)
      return if content.nil?

      # split lines preserving trailing newline behavior
      lines = content.each_line.to_a

      first_line = lines.size > 0 ? lines[0] : ""

      # determine 1-based start/stop
      sl = start_line
      sp = stop_line

      # iterate with index (1-based)
      idx = 0
      lines.each do |line|
        idx += 1
        next if idx < sl
        break if sp && idx > sp

        out_line = line

        if interactive && !@plain
          # Highlighter returns an ANSI string; pass first_line for shebang detection
          out_line = Highlighter.highlight(out_line, path, first_line || "")
        end

        if @line_numbers
          STDOUT.printf("%6d  %s", idx, out_line)
        else
          STDOUT.print out_line
        end
      end
    end

    # Helpers: safely narrow nullable tuple
    private def start_line : Int32
      lr = @lines_range
      lr ? lr[0] : 1
    end

    private def stop_line : Int32?
      lr = @lines_range
      lr ? lr[1] : nil
    end
  end
end

# tiny helper for reading all stdin content
class IO
  def read_to_end : String
    String.build do |builder|
      while chunk = self.gets
        builder << chunk
      end
    end
  end
end

# simple shellescape for temp paths / pager use later
class String
  def shellescape : String
    "'" + self.gsub("'", "'\\''") + "'"
  end
end
