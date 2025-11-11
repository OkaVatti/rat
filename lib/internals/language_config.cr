require "json"

module LanguageConfig
  class Syntax
    include JSON::Serializable

    property name : String
    property extensions : Array(String)
    property shebangs : Array(String)
    property keywords : Array(String)
    property comment_single : String?
    property comment_multi_start : String?
    property comment_multi_end : String?
    property string_delimiters : Array(String)
    property number_pattern : String?
    property operator_pattern : String?
    property function_pattern : String?

    def initialize(
      @name = "",
      @extensions = [] of String,
      @shebangs = [] of String,
      @keywords = [] of String,
      @comment_single = nil,
      @comment_multi_start = nil,
      @comment_multi_end = nil,
      @string_delimiters = ["\"", "'"],
      @number_pattern = nil,
      @operator_pattern = nil,
      @function_pattern = nil,
    )
    end
  end

  class Config
    include JSON::Serializable

    property languages : Array(Syntax)

    def initialize(@languages = [] of Syntax)
    end
  end

  @@config : Config?
  @@custom_config_path : String?

  def self.load_config(custom_path : String? = nil)
    @@custom_config_path = custom_path

    config_paths = [
      custom_path,
      File.join(ENV["HOME"]? || "", ".config", "rat", "languages.json"),
      File.join(Dir.current, "config", "languages.json"),
    ].compact

    config_paths.each do |path|
      if File.exists?(path)
        begin
          content = File.read(path)
          @@config = Config.from_json(content)
          return @@config.not_nil!
        rescue ex
          STDERR.puts "Warning: Failed to load config from #{path}: #{ex.message}"
        end
      end
    end

    @@config = default_config
    @@config.not_nil!
  end

  def self.config : Config
    @@config ||= load_config
  end

  def self.find_language(path : String, first_line : String = "") : Syntax?
    ext = File.extname(path).downcase

    config.languages.each do |lang|
      return lang if lang.extensions.includes?(ext)
    end

    if first_line.starts_with?("#!")
      config.languages.each do |lang|
        lang.shebangs.each do |shebang|
          return lang if first_line.includes?(shebang)
        end
      end
    end

    nil
  end

  private def self.default_config : Config
    Config.new([
      Syntax.new(
        name: "crystal",
        extensions: [".cr"],
        shebangs: ["crystal"],
        keywords: ["def", "class", "module", "end", "if", "else", "elsif", "unless", "while", "for", "do", "return", "break", "next", "nil", "true", "false", "self", "super", "require", "include", "extend", "private", "protected", "public", "alias", "abstract", "struct", "enum", "union", "type", "case", "when", "begin", "rescue", "ensure", "raise", "yield", "getter", "setter", "property"],
        comment_single: "#",
        string_delimiters: ["\"", "'"],
        number_pattern: "\\b\\d+(\\.\\d+)?\\b",
        function_pattern: "\\bdef\\s+(\\w+)"
      ),
      Syntax.new(
        name: "ruby",
        extensions: [".rb", ".rake", ".gemspec"],
        shebangs: ["ruby"],
        keywords: ["def", "class", "module", "end", "if", "else", "elsif", "unless", "while", "for", "do", "return", "break", "next", "nil", "true", "false", "self", "super", "require", "include", "extend", "private", "protected", "public", "alias", "begin", "rescue", "ensure", "raise", "yield", "case", "when"],
        comment_single: "#",
        string_delimiters: ["\"", "'"],
        number_pattern: "\\b\\d+(\\.\\d+)?\\b"
      ),
      Syntax.new(
        name: "rust",
        extensions: [".rs"],
        shebangs: [] of String,
        keywords: ["fn", "let", "mut", "pub", "impl", "struct", "enum", "match", "if", "else", "loop", "for", "while", "return", "break", "continue", "true", "false", "use", "mod", "trait", "type", "const", "static", "unsafe", "async", "await", "move"],
        comment_single: "//",
        comment_multi_start: "/*",
        comment_multi_end: "*/",
        string_delimiters: ["\""],
        number_pattern: "\\b\\d+(\\.\\d+)?\\b"
      ),
      Syntax.new(
        name: "python",
        extensions: [".py", ".pyw"],
        shebangs: ["python", "python3"],
        keywords: ["def", "class", "if", "else", "elif", "for", "while", "return", "True", "False", "None", "import", "from", "as", "try", "except", "finally", "raise", "with", "lambda", "yield", "async", "await", "pass", "break", "continue"],
        comment_single: "#",
        string_delimiters: ["\"", "'", "\"\"\"", "'''"],
        number_pattern: "\\b\\d+(\\.\\d+)?\\b"
      ),
      Syntax.new(
        name: "javascript",
        extensions: [".js", ".jsx", ".mjs"],
        shebangs: ["node", "nodejs"],
        keywords: ["function", "var", "let", "const", "if", "else", "return", "true", "false", "null", "import", "from", "export", "default", "class", "extends", "async", "await", "new", "this", "super", "try", "catch", "finally", "throw", "for", "while", "do", "switch", "case", "break", "continue"],
        comment_single: "//",
        comment_multi_start: "/*",
        comment_multi_end: "*/",
        string_delimiters: ["\"", "'", "`"],
        number_pattern: "\\b\\d+(\\.\\d+)?\\b"
      ),
      Syntax.new(
        name: "typescript",
        extensions: [".ts", ".tsx"],
        shebangs: [] of String,
        keywords: ["function", "var", "let", "const", "if", "else", "return", "true", "false", "null", "import", "from", "export", "default", "class", "extends", "async", "await", "new", "this", "super", "try", "catch", "finally", "throw", "interface", "type", "enum", "namespace", "public", "private", "protected", "readonly"],
        comment_single: "//",
        comment_multi_start: "/*",
        comment_multi_end: "*/",
        string_delimiters: ["\"", "'", "`"],
        number_pattern: "\\b\\d+(\\.\\d+)?\\b"
      ),
      Syntax.new(
        name: "go",
        extensions: [".go"],
        shebangs: [] of String,
        keywords: ["func", "var", "const", "if", "else", "for", "return", "true", "false", "nil", "import", "package", "type", "struct", "interface", "map", "chan", "go", "defer", "select", "case", "break", "continue", "fallthrough", "switch"],
        comment_single: "//",
        comment_multi_start: "/*",
        comment_multi_end: "*/",
        string_delimiters: ["\"", "`"],
        number_pattern: "\\b\\d+(\\.\\d+)?\\b"
      ),
      Syntax.new(
        name: "c",
        extensions: [".c", ".h"],
        shebangs: [] of String,
        keywords: ["int", "char", "float", "double", "void", "if", "else", "for", "while", "return", "break", "continue", "struct", "union", "enum", "typedef", "sizeof", "const", "static", "extern", "register", "volatile", "unsigned", "signed", "long", "short", "switch", "case", "default"],
        comment_single: "//",
        comment_multi_start: "/*",
        comment_multi_end: "*/",
        string_delimiters: ["\""],
        number_pattern: "\\b\\d+(\\.\\d+)?[fFlLuU]*\\b"
      ),
      Syntax.new(
        name: "cpp",
        extensions: [".cpp", ".cc", ".cxx", ".hpp", ".hxx", ".h++"],
        shebangs: [] of String,
        keywords: ["int", "char", "float", "double", "void", "if", "else", "for", "while", "return", "break", "continue", "struct", "union", "enum", "typedef", "sizeof", "const", "static", "extern", "class", "public", "private", "protected", "virtual", "namespace", "using", "template", "typename", "new", "delete", "this", "true", "false", "nullptr"],
        comment_single: "//",
        comment_multi_start: "/*",
        comment_multi_end: "*/",
        string_delimiters: ["\""],
        number_pattern: "\\b\\d+(\\.\\d+)?[fFlLuU]*\\b"
      ),
      Syntax.new(
        name: "java",
        extensions: [".java"],
        shebangs: [] of String,
        keywords: ["public", "private", "protected", "class", "interface", "extends", "implements", "new", "this", "super", "if", "else", "for", "while", "return", "break", "continue", "try", "catch", "finally", "throw", "throws", "import", "package", "static", "final", "abstract", "synchronized", "volatile", "transient", "native", "strictfp", "void", "int", "long", "double", "float", "boolean", "char", "byte", "short", "true", "false", "null"],
        comment_single: "//",
        comment_multi_start: "/*",
        comment_multi_end: "*/",
        string_delimiters: ["\""],
        number_pattern: "\\b\\d+(\\.\\d+)?[fFdDlL]*\\b"
      ),
      Syntax.new(
        name: "shell",
        extensions: [".sh", ".bash", ".zsh"],
        shebangs: ["sh", "bash", "zsh"],
        keywords: ["if", "then", "else", "elif", "fi", "for", "while", "do", "done", "case", "esac", "function", "return", "exit", "break", "continue", "export", "source", "alias"],
        comment_single: "#",
        string_delimiters: ["\"", "'"],
        number_pattern: "\\b\\d+\\b"
      ),
      Syntax.new(
        name: "yaml",
        extensions: [".yml", ".yaml"],
        shebangs: [] of String,
        keywords: ["true", "false", "null", "yes", "no"],
        comment_single: "#",
        string_delimiters: ["\"", "'"],
        number_pattern: "\\b\\d+(\\.\\d+)?\\b"
      ),
      Syntax.new(
        name: "json",
        extensions: [".json"],
        shebangs: [] of String,
        keywords: ["true", "false", "null"],
        comment_single: nil,
        string_delimiters: ["\""],
        number_pattern: "\\b\\d+(\\.\\d+)?([eE][+-]?\\d+)?\\b"
      ),
      Syntax.new(
        name: "markdown",
        extensions: [".md", ".markdown"],
        shebangs: [] of String,
        keywords: [] of String,
        comment_single: nil,
        string_delimiters: [] of String,
        number_pattern: nil
      ),
      Syntax.new(
        name: "html",
        extensions: [".html", ".htm"],
        shebangs: [] of String,
        keywords: [] of String,
        comment_single: nil,
        comment_multi_start: "<!--",
        comment_multi_end: "-->",
        string_delimiters: ["\"", "'"],
        number_pattern: nil
      ),
      Syntax.new(
        name: "css",
        extensions: [".css"],
        shebangs: [] of String,
        keywords: [] of String,
        comment_multi_start: "/*",
        comment_multi_end: "*/",
        string_delimiters: ["\"", "'"],
        number_pattern: "\\b\\d+(\\.\\d+)?(px|em|rem|%|vh|vw)?\\b"
      ),
      Syntax.new(
        name: "sql",
        extensions: [".sql"],
        shebangs: [] of String,
        keywords: ["SELECT", "FROM", "WHERE", "INSERT", "UPDATE", "DELETE", "CREATE", "ALTER", "DROP", "TABLE", "INDEX", "VIEW", "JOIN", "LEFT", "RIGHT", "INNER", "OUTER", "ON", "AND", "OR", "NOT", "NULL", "TRUE", "FALSE", "AS", "ORDER", "BY", "GROUP", "HAVING", "LIMIT", "OFFSET"],
        comment_single: "--",
        comment_multi_start: "/*",
        comment_multi_end: "*/",
        string_delimiters: ["'"],
        number_pattern: "\\b\\d+(\\.\\d+)?\\b"
      ),
    ])
  end
end
