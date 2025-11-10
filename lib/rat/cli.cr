module Rat
  class CLI
    @argv : Array(String)
    @files : Array(String)
    @plain : Bool
    @fast : Bool
    @paging : String # "auto", "always", "never"
    @lines_range : Tuple(Int32, Int32)?
    @max_lines : Int32?

    def self.run(argv : Array(String))
      new(argv).run
    end

    def initialize(argv : Array(String))
      @argv = argv.dup
      @files = [] of String
      @plain = false
      @fast = false
      @paging = "auto"
      @lines_range = nil
      @max_lines = nil
      parse_args
    end

    def parse_args
      while @argv.any?
        arg = @argv.shift
        case arg
        when "--plain"
          @plain = true
        when "--fast"
          @fast = true
        when /\A--paging=(auto|always|never)\z/
          @paging = $1
        when /\A--lines=(\d+)-(\d+)\z/
          start_i = $1.to_i32
          stop_i = $2.to_i32
          if start_i <= 0 || stop_i <= 0 || stop_i < start_i
            STDERR.puts "Invalid --lines range"
            exit 1
          end
          @lines_range = {start_i, stop_i}
        when /\A--max-lines=(\d+)\z/
          @max_lines = $1.to_i32
        when "-n", "--number"
          # assume line numbers enabled by other logic
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

      @files << "-" if @files.empty?
    end

    def help : String
      <<-HELP
        rat — smart, minimal file viewer
        Usage:
          rat [options] [files...]
            
        Options:
          --plain                Raw output mode (no decoration)
          --fast                 Disable highlighting for large files
          --paging=auto|always|never
          --lines=START‑END       Show only inclusive line range (1‑based)
          --max-lines=N           Stop after N lines
          -h, --help             Show this help
      HELP
    end

    def run
      interactive = STDOUT.tty?
      use_rich = interactive && !@plain

      # Handle paging
      if use_rich && @paging == "auto"
        pager = ENV["PAGER"]? || "less -R"
        system("#{pager} #{shellescape_paths(@files)}") && return
      elsif @paging == "always"
        pager = ENV["PAGER"]? || "less -R"
        system("#{pager} #{shellescape_paths(@files)}") && return
      end

      @files.each do |path|
        Formatter.print_header_if_needed(path, use_rich, @plain)
        Reader.each_line(path, fast: @fast) do |line, line_num, first_line|
          if @lines_range
            start_i, stop_i = @lines_range
            next if line_num < start_i
            break if line_num > stop_i
          end

          if ml = @max_lines
            break if line_num > ml
          end

          formatted = Formatter.format_line(
            line, path,
            line_num: line_num,
            line_numbers: false, # add logic to enable
            plain: !use_rich,
            first_line: first_line
          )

          STDOUT.print formatted
        end
      end
    end

    private def shellescape_paths(paths : Array(String)) : String
      paths.map { |p| "'" + p.gsub("'", "'\\''") + "'" }.join(" ")
    end
  end
end
