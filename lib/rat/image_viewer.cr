module Rat
  module ImageViewer
    IMAGE_EXTENSIONS = [".jpg", ".jpeg", ".png", ".gif", ".webp", ".svg", ".ico", ".bmp"]

    def self.is_image?(path : String) : Bool
      ext = File.extname(path).downcase
      IMAGE_EXTENSIONS.includes?(ext)
    end

    def self.can_display_inline? : Bool
      term = ENV["TERM"]?
      term_program = ENV["TERM_PROGRAM"]?

      return true if term_program == "iTerm.app"
      return true if term == "xterm-kitty"
      return true if ENV["TERMINOLOGY"]? == "1"
      return true if can_use_w3m?

      false
    end

    def self.display_image(path : String, plain : Bool = false) : String
      return "Image viewing disabled in plain mode" if plain

      unless File.exists?(path)
        return "Error: Image file not found: #{path}"
      end

      protocol = detect_protocol

      case protocol
      when :kitty
        display_kitty(path)
      when :iterm2
        display_iterm2(path)
      when :w3m
        display_w3m(path)
      when :sixel
        display_sixel(path)
      else
        display_fallback(path)
      end
    end

    private def self.detect_protocol : Symbol
      term_program = ENV["TERM_PROGRAM"]?
      term = ENV["TERM"]?

      return :iterm2 if term_program == "iTerm.app"
      return :kitty if term == "xterm-kitty"
      return :w3m if can_use_w3m?
      return :sixel if can_use_sixel?

      :none
    end

    private def self.can_use_w3m? : Bool
      system("which w3m > /dev/null 2>&1")
    end

    private def self.can_use_sixel? : Bool
      system("which img2sixel > /dev/null 2>&1")
    end

    private def self.display_kitty(path : String) : String
      begin
        file_data = File.read(path)
        encoded = Base64.strict_encode(file_data)

        chunks = encoded.scan(/.{1,4096}/)
        output = String.build do |str|
          chunks.each_with_index do |chunk, idx|
            m = idx == chunks.size - 1 ? 0 : 1
            str << "\e_Ga=T,f=100,m=#{m};#{chunk}\e\\"
          end
          str << "\n"
        end
        output
      rescue ex
        "Error displaying image with Kitty protocol: #{ex.message}"
      end
    end

    private def self.display_iterm2(path : String) : String
      begin
        file_data = File.read(path)
        encoded = Base64.strict_encode(file_data)

        "\e]1337;File=inline=1:#{encoded}\a\n"
      rescue ex
        "Error displaying image with iTerm2 protocol: #{ex.message}"
      end
    end

    private def self.display_w3m(path : String) : String
      result = `w3m -dump "#{path}" 2>&1`
      result.empty? ? "[Image displayed via w3m]\n" : result
    rescue ex
      "Error displaying image with w3m: #{ex.message}"
    end

    private def self.display_sixel(path : String) : String
      result = `img2sixel "#{path}" 2>&1`
      result
    rescue ex
      "Error displaying image with sixel: #{ex.message}"
    end

    private def self.display_fallback(path : String) : String
      stat = File.info(path)
      ext = File.extname(path).upcase[1..]

      output = String.build do |str|
        str << "\e[1;35m" << "=" * 60 << "\e[0m\n"
        str << "\e[1;36mImage File\e[0m: #{path}\n"
        str << "\e[1;36mFormat\e[0m: #{ext}\n"
        str << "\e[1;36mSize\e[0m: #{format_size(stat.size)}\n"
        str << "\e[1;36mDimensions\e[0m: #{get_image_dimensions(path)}\n"
        str << "\e[1;35m" << "=" * 60 << "\e[0m\n"
        str << "\n"
        str << "\e[33mNote:\e[0m Terminal does not support inline image display.\n"
        str << "Supported protocols: Kitty, iTerm2, w3m, Sixel\n"
      end

      output
    end

    private def self.get_image_dimensions(path : String) : String
      result = `file "#{path}" 2>/dev/null`
      if result =~ /(\d+)\s*x\s*(\d+)/
        "#{$1}x#{$2}"
      else
        "Unknown"
      end
    rescue
      "Unknown"
    end

    private def self.format_size(bytes : Int64) : String
      units = ["B", "KB", "MB", "GB"]
      size = bytes.to_f
      unit_idx = 0

      while size >= 1024 && unit_idx < units.size - 1
        size /= 1024
        unit_idx += 1
      end

      "%.2f %s" % [size, units[unit_idx]]
    end
  end
end
