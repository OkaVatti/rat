require "json"

module Rat
  module StructuredViewer
    def self.can_view_structured?(path : String, content : String) : Bool
      ext = File.extname(path).downcase
      return true if [".json", ".csv"].includes?(ext)

      begins_with_json?(content)
    end

    def self.view_structured(path : String, content : String, plain : Bool = false) : String
      ext = File.extname(path).downcase

      case ext
      when ".json"
        view_json(content, plain)
      when ".csv"
        view_csv(content, plain)
      else
        if begins_with_json?(content)
          view_json(content, plain)
        else
          content
        end
      end
    end

    private def self.begins_with_json?(content : String) : Bool
      trimmed = content.lstrip
      trimmed.starts_with?("{") || trimmed.starts_with?("[")
    end

    private def self.view_json(content : String, plain : Bool) : String
      begin
        parsed = JSON.parse(content)
        render_json_tree(parsed, plain)
      rescue ex
        "Error parsing JSON: #{ex.message}\n\n#{content}"
      end
    end

    private def self.render_json_tree(value : JSON::Any, plain : Bool, indent : Int32 = 0, prefix : String = "") : String
      output = String.build do |str|
        case value.raw
        when Hash
          hash = value.as_h
          hash.each_with_index do |(key, val), idx|
            is_last = idx == hash.size - 1
            connector = is_last ? "└─" : "├─"
            child_prefix = is_last ? "  " : "│ "

            if plain
              str << "  " * indent << key << ": "
            else
              str << "  " * indent << "\e[36m#{connector}\e[0m \e[33m#{key}\e[0m: "
            end

            if val.as_h? || val.as_a?
              str << "\n"
              str << render_json_tree(val, plain, indent + 1, prefix + child_prefix)
            else
              str << format_json_value(val, plain) << "\n"
            end
          end
        when Array
          array = value.as_a
          array.each_with_index do |val, idx|
            is_last = idx == array.size - 1
            connector = is_last ? "└─" : "├─"
            child_prefix = is_last ? "  " : "│ "

            if plain
              str << "  " * indent << "[#{idx}]: "
            else
              str << "  " * indent << "\e[36m#{connector}\e[0m \e[35m[#{idx}]\e[0m: "
            end

            if val.as_h? || val.as_a?
              str << "\n"
              str << render_json_tree(val, plain, indent + 1, prefix + child_prefix)
            else
              str << format_json_value(val, plain) << "\n"
            end
          end
        else
          str << format_json_value(value, plain)
        end
      end
      output
    end

    private def self.format_json_value(value : JSON::Any, plain : Bool) : String
      case value.raw
      when String
        plain ? "\"#{value.as_s}\"" : "\e[32m\"#{value.as_s}\"\e[0m"
      when Int64, Float64
        plain ? value.to_s : "\e[35m#{value}\e[0m"
      when Bool
        plain ? value.to_s : "\e[33m#{value}\e[0m"
      when Nil
        plain ? "null" : "\e[90mnull\e[0m"
      else
        value.to_s
      end
    end

    private def self.view_csv(content : String, plain : Bool) : String
      lines = content.lines
      return content if lines.empty?

      header = lines[0].split(",").map(&.strip)
      rows = lines[1..-1].map { |line| line.split(",").map(&.strip) }

      col_widths = header.map_with_index do |h, idx|
        max_width = h.size
        rows.each do |row|
          cell = row[idx]? || ""
          max_width = cell.size if cell.size > max_width
        end
        [max_width, 50].min
      end

      output = String.build do |str|
        if plain
          str << header.map_with_index { |h, i| h.ljust(col_widths[i]) }.join(" | ") << "\n"
          str << col_widths.map { |w| "-" * w }.join("-+-") << "\n"
        else
          str << "\e[1;36m"
          str << header.map_with_index { |h, i| h.ljust(col_widths[i]) }.join(" │ ")
          str << "\e[0m\n"
          str << "\e[36m"
          str << col_widths.map { |w| "─" * w }.join("─┼─")
          str << "\e[0m\n"
        end

        rows.each do |row|
          str << row.map_with_index { |cell, i| cell.ljust(col_widths[i]) }.join(" │ ") << "\n"
        end
      end

      output
    end
  end
end
