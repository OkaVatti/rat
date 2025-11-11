# lib/rat/reader.cr
require "file"

module Rat
  module Reader
    MAX_FILE_SIZE = 100_000_000

    def self.each_line(path : String, &block : String, Int32, String ->)
      if path == "-"
        read_stdin(&block)
      else
        read_file(path, &block)
      end
    end

    def self.read_content(path : String) : String
      if path == "-"
        read_stdin_content
      else
        read_file_content(path)
      end
    end

    private def self.read_stdin(&block : String, Int32, String ->)
      begin
        first_line = ""
        line_num = 0
        STDIN.each_line do |line|
          line_num += 1
          first_line = line if line_num == 1
          block.call(sanitize_line(line), line_num, first_line)
        end
      rescue ex
        STDERR.puts "rat: error reading stdin: #{ex.message}"
      end
    end

    private def self.read_stdin_content : String
      begin
        content = STDIN.gets_to_end
        sanitize_content(content)
      rescue ex
        STDERR.puts "rat: error reading stdin: #{ex.message}"
        ""
      end
    end

    private def self.read_file(path : String, &block : String, Int32, String ->)
      validate_file(path)

      begin
        File.open(path, "r") do |f|
          first_line = ""
          line_num = 0
          f.each_line do |line|
            line_num += 1
            first_line = line if line_num == 1
            block.call(sanitize_line(line), line_num, first_line)
          end
        end
      rescue ex
        STDERR.puts "rat: cannot open #{path}: #{ex.message}"
      end
    end

    private def self.read_file_content(path : String) : String
      validate_file(path)

      begin
        content = File.read(path)
        sanitize_content(content)
      rescue ex
        STDERR.puts "rat: cannot open #{path}: #{ex.message}"
        ""
      end
    end

    private def self.validate_file(path : String)
      unless File.exists?(path)
        raise "File not found: #{path}"
      end

      unless File.readable?(path)
        raise "File not readable: #{path}"
      end

      stat = File.info(path)
      if stat.size > MAX_FILE_SIZE
        STDERR.puts "Warning: File #{path} is very large (#{stat.size} bytes)"
      end
    end

    private def self.sanitize_line(line : String) : String
      line.gsub(/[\x00-\x08\x0B-\x0C\x0E-\x1F]/, "")
    end

    private def self.sanitize_content(content : String) : String
      content.gsub(/[\x00-\x08\x0B-\x0C\x0E-\x1F]/, "")
    end
  end
end
