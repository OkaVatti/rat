# internals/highlighter.cr
# Improved lightweight highlighter and language detection.
module Highlighter
  RESET         = "\e[0m"
  BOLD          = "\e[1m"
  KEYWORD_COLOR = "\e[33m" # yellow-ish
  STRING_COLOR  = "\e[32m" # green
  COMMENT_COLOR = "\e[90m" # bright black / grey
  NUMBER_COLOR  = "\e[35m" # magenta-ish

  # public: detect language from path or first line (shebang)
  def self.detect_language(path : String = "", first_line : String = "")
    ext = File.extname(path).downcase
    return "crystal" if ext == ".cr"
    return "ruby" if ext == ".rb"
    return "rust" if ext == ".rs"
    return "python" if ext == ".py"
    return "js" if %w(.js .jsx .ts .tsx).includes?(ext)
    # try shebang
    if first_line && first_line.starts_with?("#!")
      return "python" if first_line.includes?("python")
      return "ruby" if first_line.includes?("ruby")
      return "node" if first_line.includes?("node") || first_line.includes?("nodejs")
      return "sh" if first_line.includes?("sh") || first_line.includes?("bash")
    end
    "" # unknown
  end

  # Public entry: highlight a single line given a language (preferred) or path.
  def self.highlight(line : String, path : String = "", first_line : String = "")
    lang = detect_language(path, first_line)
    case lang
    when "crystal"
      highlight_ruby_like(line)
    when "ruby"
      highlight_ruby_like(line)
    when "rust"
      highlight_rust(line)
    when "python"
      highlight_python(line)
    when "js", "node"
      highlight_js_like(line)
    else
      # fallback: minimal generic highlighting (numbers + strings + comments)
      highlight_generic(line)
    end
  end

  private def self.highlight_generic(line : String)
    s = line
    s = s.gsub(/"([^"\\]|\\.)*"|'([^'\\]|\\.)*'/) { |m| "#{STRING_COLOR}#{m}#{RESET}" }
    s = s.gsub(/\b\d+(\.\d+)?\b/) { |m| "#{NUMBER_COLOR}#{m}#{RESET}" }
    s = s.gsub(/#.*/) { |m| "#{COMMENT_COLOR}#{m}#{RESET}" } # naive for many languages
    s
  end

  private def self.wrap_string_regex(line : String)
    line = line.gsub(/"([^"\\]|\\.)*"|'([^'\\]|\\.)*'/) { |m| "#{STRING_COLOR}#{m}#{RESET}" }
    line
  end

  private def self.highlight_ruby_like(line : String)
    keywords = %w(def class module end if else elsif unless while for do return break next nil true false self super)
    rx = /\b(#{keywords.join("|")})\b/
    line = line.gsub(/#.*$/) { |m| "#{COMMENT_COLOR}#{m}#{RESET}" }
    line = wrap_string_regex(line)
    line = line.gsub(rx) { |m| "#{KEYWORD_COLOR}#{m}#{RESET}" }
    line
  end

  private def self.highlight_rust(line : String)
    keywords = %w(fn let mut pub impl struct enum match if else loop for while return break true false)
    rx = /\b(#{keywords.join("|")})\b/
    line = line.gsub(/\/\/.*$/) { |m| "#{COMMENT_COLOR}#{m}#{RESET}" }
    line = wrap_string_regex(line)
    line = line.gsub(rx) { |m| "#{KEYWORD_COLOR}#{m}#{RESET}" }
    line = line.gsub(/\b\d+(\.\d+)?\b/) { |m| "#{NUMBER_COLOR}#{m}#{RESET}" }
    line
  end

  private def self.highlight_python(line : String)
    keywords = %w(def class if else elif for while return True False None import from as)
    rx = /\b(#{keywords.join("|")})\b/
    line = line.gsub(/#.*$/) { |m| "#{COMMENT_COLOR}#{m}#{RESET}" }
    line = wrap_string_regex(line)
    line = line.gsub(rx) { |m| "#{KEYWORD_COLOR}#{m}#{RESET}" }
    line
  end

  private def self.highlight_js_like(line : String)
    keywords = %w(function var let const if else return true false null import from export default)
    rx = /\b(#{keywords.join("|")})\b/
    line = line.gsub(/\/\/.*$/) { |m| "#{COMMENT_COLOR}#{m}#{RESET}" }
    line = wrap_string_regex(line)
    line = line.gsub(rx) { |m| "#{KEYWORD_COLOR}#{m}#{RESET}" }
    line = line.gsub(/\b\d+(\.\d+)?\b/) { |m| "#{NUMBER_COLOR}#{m}#{RESET}" }
    line
  end
end
