require "./language_config"

module Highlighter
  RESET          = "\e[0m"
  BOLD           = "\e[1m"
  KEYWORD_COLOR  = "\e[33m"
  STRING_COLOR   = "\e[32m"
  COMMENT_COLOR  = "\e[90m"
  NUMBER_COLOR   = "\e[35m"
  OPERATOR_COLOR = "\e[36m"
  FUNCTION_COLOR = "\e[94m"

  def self.detect_language(path : String = "", first_line : String = "")
    lang = LanguageConfig.find_language(path, first_line)
    lang ? lang.name : ""
  end

  def self.highlight(line : String, path : String = "", first_line : String = "") : String
    lang_config = LanguageConfig.find_language(path, first_line)
    return line unless lang_config

    highlight_with_config(line, lang_config)
  end

  private def self.highlight_with_config(line : String, config : LanguageConfig::Syntax) : String
    result = line.dup

    if comment_single = config.comment_single
      if idx = result.index(comment_single)
        before = result[0...idx]
        comment = result[idx..-1]
        result = before + "#{COMMENT_COLOR}#{comment}#{RESET}"
        return result
      end
    end

    string_patterns = config.string_delimiters.map do |delim|
      escaped_delim = Regex.escape(delim)
      /#{escaped_delim}([^#{escaped_delim}\\]|\\.)*#{escaped_delim}/
    end

    string_patterns.each do |pattern|
      result = result.gsub(pattern) { |m| "#{STRING_COLOR}#{m}#{RESET}" }
    end

    if config.keywords.any?
      keywords_rx = /\b(#{config.keywords.join("|")})\b/
      result = result.gsub(keywords_rx) { |m| "#{KEYWORD_COLOR}#{m}#{RESET}" }
    end

    if number_pattern = config.number_pattern
      result = result.gsub(/#{number_pattern}/) { |m| "#{NUMBER_COLOR}#{m}#{RESET}" }
    end

    result
  end

  def self.strip_ansi(text : String) : String
    text.gsub(/\e\[[0-9;]*m/, "")
  end
end
