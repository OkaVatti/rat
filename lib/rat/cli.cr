# lib/rat/cli.cr
require "./formatter"
require "./reader"
require "./ssh_client"
require "./archive_reader"
require "./image_viewer"
require "./structured_viewer"
require "./git_annotator"
require "./plugin_manager"
require "../internals/language_config"

module Rat
  class CLI
    @argv : Array(String)
    @files : Array(String)
    @plain : Bool
    @fast : Bool
    @line_numbers : Bool
    @paging : String
    @lines_range : Tuple(Int32, Int32)?
    @max_lines : Int32?
    @ssh_enabled : Bool
    @ssh_location : String?
    @ssh_key : String?
    @ssh_password : String?
    @remote_path : String?
    @git_annotate : Bool
    @config_file : String?
    @list_plugins : Bool
    @plugin_manager : PluginManager?

    def self.run(argv : Array(String))
      new(argv).run
    end

    def initialize(argv : Array(String))
      @argv = argv.dup
      @files = [] of String
      @plain = false
      @fast = false
      @line_numbers = false
      @paging = "auto"
      @lines_range = nil
      @max_lines = nil
      @ssh_enabled = false
      @ssh_location = nil
      @ssh_key = nil
      @ssh_password = nil
      @remote_path = nil
      @git_annotate = false
      @config_file = nil
      @list_plugins = false
      @plugin_manager = nil

      parse_args
      load_language_config if @config_file
    end

    def parse_args
      while @argv.any?
        arg = @argv.shift
        case arg
        when "--plain"
          @plain = true
        when "--fast"
          @fast = true
        when "-n", "--number"
          @line_numbers = true
        when /\A--paging=(auto|always|never)\z/
          @paging = $1
        when /\A--lines=(\d+)-(\d+)\z/
          start_i = $1.to_i32
          stop_i = $2.to_i32
          if start_i <= 0 || stop_i <= 0 || stop_i < start_i
            STDERR.puts "Invalid --lines range. Use 1-based START-END with START <= END"
            exit 1
          end
          @lines_range = {start_i, stop_i}
        when /\A--max-lines=(\d+)\z/
          @max_lines = $1.to_i32
        when "-S", "--ssh"
          @ssh_enabled = true
        when "-L", "--location"
          @ssh_location = @argv.shift
        when "-K", "--key"
          @ssh_key = @argv.shift
        when "-P", "--password"
          @ssh_password = @argv.shift
        when "-l", "--remote-file"
          @remote_path = @argv.shift
        when "-g", "--git-annotate"
          @git_annotate = true
        when "-c", "--config"
          @config_file = @argv.shift
        when "--list-plugins"
          @list_plugins = true
        when "-h", "--help"
          puts help
          exit 0
        when "-v", "--version"
          puts "rat version 1.0.0"
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

      if @ssh_enabled && @remote_path.nil? && @files.empty?
        STDERR.puts "Error: SSH mode requires --remote-file (-l) or file arguments"
        exit 1
      end

      @files << "-" if @files.empty? && !@ssh_enabled && @remote_path.nil?
    end

    def help : String
      <<-HELP
        rat - smart, minimal file viewer with extended capabilities
        
        Usage:
          rat [options] [files...]
        
        Basic Options:
          --plain                   Raw output mode (no decoration)
          --fast                    Disable highlighting for large files
          --paging=auto|always|never Control pager behavior
          --lines=START-END         Show only inclusive line range (1-based)
          --max-lines=N             Stop after N lines
          -n, --number              Show line numbers
          -h, --help                Show this help
          -v, --version             Show version
        
        SSH Options:
          -S, --ssh                 Enable SSH mode
          -L, --location USER@HOST:PORT SSH location (default port: 22)
          -K, --key PATH            Path to SSH private key
          -P, --password PASS       SSH password (prompts if not provided)
          -l, --remote-file PATH    Remote file path to read
        
        Extended Features:
          -g, --git-annotate        Show git blame annotations
          -c, --config PATH         Custom language config file
          --list-plugins            List available plugins
        
        Supported Features:
          - Syntax highlighting for 15+ languages
          - Archive viewing (.gz, .bz2, .tar, .zip, etc.)
          - Structured data viewing (JSON trees, CSV tables)
          - Inline image display (Kitty, iTerm2, w3m, Sixel)
          - Git blame annotations
          - Plugin system for custom renderers
          - SSH file viewing
        
        Examples:
          # Basic file viewing
          rat file.cr
          
          # SSH file viewing
          rat -S -L user@host:22 -K ~/.ssh/id_rsa -l /path/to/file.rs
          
          # Git annotations with line numbers
          rat -g -n main.cr
          
          # View JSON as tree
          rat data.json
          
          # View compressed file
          rat archive.gz
          
          # View image (if terminal supports it)
          rat image.png
      HELP
    end

    def run
      if @list_plugins
        list_available_plugins
        return
      end

      interactive = STDOUT.tty?
      use_rich = interactive && !@plain

      if @ssh_enabled
        handle_ssh_mode(use_rich)
        return
      end

      if use_rich && @paging == "auto" && estimate_output_size > 1000
        use_pager
        return
      elsif @paging == "always"
        use_pager
        return
      end

      @files.each_with_index do |path, idx|
        process_file(path, use_rich)

        if interactive && !@plain && idx < @files.size - 1
          puts ""
        end
      end
    end

    private def handle_ssh_mode(use_rich : Bool)
      location = @ssh_location
      unless location
        STDERR.puts "Error: SSH location required (-L user@host:port)"
        exit 1
      end

      begin
        user, host, port = SSHClient.parse_location(location)
        client = SSHClient.new(host, port, user, @ssh_key, @ssh_password)

        puts "Connecting to #{user}@#{host}:#{port}..." if use_rich
        client.connect
        puts "Connected." if use_rich

        files_to_fetch = @remote_path ? [@remote_path.not_nil!] : @files

        files_to_fetch.each do |remote_path|
          unless client.file_exists?(remote_path)
            STDERR.puts "Error: Remote file not found: #{remote_path}"
            next
          end

          content = client.read_file(remote_path)
          process_content(remote_path, content, use_rich)
        end

        client.close
      rescue ex
        STDERR.puts "SSH Error: #{ex.message}"
        exit 1
      end
    end

    private def process_file(path : String, use_rich : Bool)
      sanitized_path = Formatter.sanitize_path(path)

      if ImageViewer.is_image?(sanitized_path)
        Formatter.print_header_if_needed(sanitized_path, use_rich, @plain)
        output = ImageViewer.display_image(sanitized_path, @plain)
        STDOUT.print output
        return
      end

      if ArchiveReader.is_archive?(sanitized_path)
        Formatter.print_header_if_needed(sanitized_path, use_rich, @plain)
        content = ArchiveReader.read_archive(sanitized_path)
        STDOUT.print content
        return
      end

      content = Reader.read_content(sanitized_path)
      process_content(sanitized_path, content, use_rich)
    end

    private def process_content(path : String, content : String, use_rich : Bool)
      if content.empty?
        return
      end

      plugin_manager = get_plugin_manager
      if plugin = plugin_manager.find_plugin(path)
        if result = plugin_manager.execute_plugin(plugin, path, content)
          Formatter.print_header_if_needed(path, use_rich, @plain)
          STDOUT.print result
          return
        end
      end

      if !@plain && StructuredViewer.can_view_structured?(path, content)
        Formatter.print_header_if_needed(path, use_rich, @plain)
        output = StructuredViewer.view_structured(path, content, @plain)
        STDOUT.print output
        return
      end

      if @git_annotate && GitAnnotator.is_git_repo?(path)
        Formatter.print_header_if_needed(path, use_rich, @plain)
        output = GitAnnotator.annotate_file(path, content, @plain)
        STDOUT.print output
        return
      end

      Formatter.print_header_if_needed(path, use_rich, @plain)
      output_lines(content, path, use_rich)
    end

    private def output_lines(content : String, path : String, use_rich : Bool)
      lines = content.lines
      first_line = lines.first? || ""

      start_line, end_line = get_line_range

      lines.each_with_index do |line, idx|
        line_num = idx + 1

        next if line_num < start_line
        break if end_line && line_num > end_line
        break if max = @max_lines; max && line_num > max

        formatted = Formatter.format_line(
          line,
          path,
          line_num: line_num,
          line_numbers: @line_numbers,
          plain: !use_rich,
          first_line: first_line
        )

        sanitized = Formatter.sanitize_output(formatted)
        STDOUT.print sanitized
      end
    end

    private def get_line_range : Tuple(Int32, Int32?)
      if range = @lines_range
        {range[0], range[1]}
      else
        {1, nil}
      end
    end

    # --- FIXED: return an Int32, avoid Float64 result from division ---
    private def estimate_output_size : Int32
      total = 0_i64
      @files.each do |path|
        next if path == "-"
        begin
          stat = File.info(path)
          total += stat.size
        rescue
          # ignore
        end
      end
      # rough estimate: characters per terminal column (80)
      (total / 80_i64).to_i32
    end

    private def use_pager
      pager = ENV["PAGER"]? || "less -R"

      files_arg = @files.map { |f| shellescape(f) }.join(" ")
      system("#{pager} #{files_arg}")
    end

    private def shellescape(path : String) : String
      "'" + path.gsub("'", "'\\''") + "'"
    end

    private def load_language_config
      if config_file = @config_file
        LanguageConfig.load_config(config_file)
      end
    end

    private def get_plugin_manager : PluginManager
      @plugin_manager ||= PluginManager.new
    end

    private def list_available_plugins
      manager = get_plugin_manager
      plugins = manager.list_plugins

      if plugins.empty?
        puts "No plugins installed."
        puts "\nPlugin directory: #{File.join(ENV["HOME"]? || "", ".config", "rat", "plugins")}"
        return
      end

      puts "\e[1;36mInstalled Plugins:\e[0m\n"
      plugins.each do |plugin|
        puts "\e[1;33m#{plugin.name}\e[0m v#{plugin.version}"
        puts "  File types: #{plugin.file_types.join(", ")}"
        if desc = plugin.description
          puts "  Description: #{desc}"
        end
        puts ""
      end
    end
  end
end
