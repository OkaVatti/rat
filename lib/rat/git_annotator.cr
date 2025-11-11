module Rat
  module GitAnnotator
    def self.is_git_repo?(path : String) : Bool
      dir = File.directory?(path) ? path : File.dirname(path)
      while dir != "/"
        return true if File.directory?(File.join(dir, ".git"))
        dir = File.dirname(dir)
      end
      false
    end

    def self.annotate_file(path : String, content : String, plain : Bool = false) : String
      return content unless is_git_repo?(path) && File.exists?(path)

      blame_output = get_git_blame(path)
      return content if blame_output.empty?

      lines = content.lines
      blame_lines = blame_output.lines

      output = String.build do |str|
        lines.each_with_index do |line, idx|
          blame_info = blame_lines[idx]? || ""

          if blame_info =~ /^(\w+)\s+\((.+?)\s+(\d{4}-\d{2}-\d{2})/
            commit = $1[0..7]
            author = $2.strip
            date = $3

            if plain
              str << "[#{commit} #{author} #{date}] #{line}\n"
            else
              str << "\e[90m#{commit}\e[0m \e[34m#{author[0..15].ljust(16)}\e[0m \e[32m#{date}\e[0m │ #{line}\n"
            end
          else
            str << line << "\n"
          end
        end
      end

      output
    end

    private def self.get_git_blame(path : String) : String
      `git blame -w --date=short "#{path}" 2>/dev/null`
    rescue
      ""
    end
  end
end
