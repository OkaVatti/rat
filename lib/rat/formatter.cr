require "../internals/highlighter"

module Rat
  module Formatter
    def self.print_header_if_needed(path : String, interactive : Bool, plain : Bool)
      return unless interactive && !plain

      stat = begin
        path == "<stdin>" ? nil : File.info(path)
      rescue
        nil
      end

      if stat
        size = format_file_size(stat.size)
        mtime = stat.modification_time.to_s("%Y-%m-%d %H:%M:%S")
        STDOUT.puts "\e[1;34m==> #{path}\e[0m  (\e[33m#{size}\e[0m, \e[32m#{mtime}\e[0m)"
      else
        STDOUT.puts "\e[1;34m==> #{path}\e[0m"
      end
    end

    def self.format_line(
      line : String,
      path : String,
      line_num : Int32 = 0,
      line_numbers : Bool = false,
      plain : Bool = false,
      first_line : String = "",
    ) : String
      content = plain ? line : Highlighter.highlight(line, path, first_line)

      if line_numbers && line_num > 0
        num_width = 6
        if plain
          "%#{num_width}d  %s\n" % [line_num, content]
        else
          "\e[90m%#{num_width}d\e[0m  %s\n" % [line_num, content]
        end
      else
        "#{content}\n"
      end
    end

    def self.format_file_size(bytes : Int64) : String
      units = ["B", "KB", "MB", "GB", "TB"]
      size = bytes.to_f
      unit_idx = 0

      while size >= 1024 && unit_idx < units.size - 1
        size /= 1024
        unit_idx += 1
      end

      if unit_idx == 0
        "#{bytes} #{units[unit_idx]}"
      else
        "%.2f %s" % [size, units[unit_idx]]
      end
    end

    def self.sanitize_output(text : String) : String
      text.gsub(/[\x00-\x08\x0B-\x0C\x0E-\x1F\x7F]/, "")
    end

    def self.sanitize_path(path : String) : String
      return path if path == "-"

      path = path.strip
      path = path.gsub(/\.\./, "")
      path = path.gsub(/[<>:"|?*]/, "")

      path
    end
  end
end
