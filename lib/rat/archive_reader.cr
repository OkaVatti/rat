require "compress/gzip"
require "compress/zlib"

module Rat
  module ArchiveReader
    ARCHIVE_EXTENSIONS = {
      ".gz"      => :gzip,
      ".gzip"    => :gzip,
      ".bz2"     => :bzip2,
      ".bz"      => :bzip2,
      ".xz"      => :xz,
      ".lz"      => :lzip,
      ".lzma"    => :lzma,
      ".tar"     => :tar,
      ".tgz"     => :tar_gzip,
      ".tar.gz"  => :tar_gzip,
      ".tbz"     => :tar_bzip2,
      ".tbz2"    => :tar_bzip2,
      ".tar.bz2" => :tar_bzip2,
      ".txz"     => :tar_xz,
      ".tar.xz"  => :tar_xz,
      ".zip"     => :zip,
      ".rar"     => :rar,
      ".7z"      => :seven_zip,
      ".iso"     => :iso,
      ".img"     => :img,
      ".ipa"     => :ipa,
      ".apk"     => :apk,
      ".jar"     => :jar,
      ".war"     => :war,
      ".ear"     => :ear,
    }

    def self.is_archive?(path : String) : Bool
      ext = get_extension(path)
      ARCHIVE_EXTENSIONS.has_key?(ext)
    end

    def self.get_extension(path : String) : String
      # Handle double extensions like .tar.gz
      if path =~ /\.(tar\.(gz|bz2?|xz|lz|lzma))$/i
        ".#{$1.downcase}"
      else
        File.extname(path).downcase
      end
    end

    def self.detect_format(path : String) : Symbol?
      ext = get_extension(path)
      ARCHIVE_EXTENSIONS[ext]?
    end

    def self.read_archive(path : String, plain : Bool = false) : String
      format = detect_format(path)
      return "Unknown archive format" unless format

      case format
      when :gzip
        read_gzip(path, plain)
      when :bzip2
        read_bzip2(path, plain)
      when :xz
        read_xz(path, plain)
      when :lzip
        read_lzip(path, plain)
      when :lzma
        read_lzma(path, plain)
      when :tar
        list_tar(path, plain)
      when :tar_gzip
        list_tar_compressed(path, "gzip", plain)
      when :tar_bzip2
        list_tar_compressed(path, "bzip2", plain)
      when :tar_xz
        list_tar_compressed(path, "xz", plain)
      when :zip, :ipa, :apk, :jar, :war, :ear
        list_zip(path, plain)
      when :rar
        list_rar(path, plain)
      when :seven_zip
        list_7z(path, plain)
      when :iso
        list_iso(path, plain)
      when :img
        list_img(path, plain)
      else
        "Unsupported archive format: #{format}"
      end
    end

    # Gzip decompression using Crystal's built-in
    private def self.read_gzip(path : String, plain : Bool) : String
      begin
        File.open(path, "r") do |file|
          Compress::Gzip::Reader.open(file) do |gzip|
            content = gzip.gets_to_end
            if content.size > 1_000_000
              header(path, "Gzip Compressed File", plain) +
                "[Content too large to display. Size: #{format_size(content.size)}]\n"
            else
              header(path, "Gzip Compressed File", plain) + content
            end
          end
        end
      rescue ex
        "Error reading gzip archive: #{ex.message}"
      end
    end

    # Bzip2 decompression using system bzip2
    private def self.read_bzip2(path : String, plain : Bool) : String
      return "bzip2 not installed" unless command_exists?("bzip2")

      begin
        output = String.build do |str|
          process = Process.new(
            "bzip2",
            ["-dc", path],
            output: Process::Redirect::Pipe,
            error: Process::Redirect::Pipe
          )

          content = process.output.gets_to_end
          error = process.error.gets_to_end
          status = process.wait

          if status.success?
            if content.size > 1_000_000
              str << header(path, "Bzip2 Compressed File", plain)
              str << "[Content too large to display. Size: #{format_size(content.size)}]\n"
            else
              str << header(path, "Bzip2 Compressed File", plain)
              str << content
            end
          else
            str << "Error: #{error}"
          end
        end
        output
      rescue ex
        "Error reading bzip2 archive: #{ex.message}"
      end
    end

    # XZ decompression
    private def self.read_xz(path : String, plain : Bool) : String
      return "xz not installed" unless command_exists?("xz")

      begin
        output = String.build do |str|
          process = Process.new(
            "xz",
            ["-dc", path],
            output: Process::Redirect::Pipe,
            error: Process::Redirect::Pipe
          )

          content = process.output.gets_to_end
          error = process.error.gets_to_end
          status = process.wait

          if status.success?
            if content.size > 1_000_000
              str << header(path, "XZ Compressed File", plain)
              str << "[Content too large to display. Size: #{format_size(content.size)}]\n"
            else
              str << header(path, "XZ Compressed File", plain)
              str << content
            end
          else
            str << "Error: #{error}"
          end
        end
        output
      rescue ex
        "Error reading xz archive: #{ex.message}"
      end
    end

    # Lzip decompression
    private def self.read_lzip(path : String, plain : Bool) : String
      return "lzip not installed" unless command_exists?("lzip")

      begin
        output = String.build do |str|
          process = Process.new(
            "lzip",
            ["-dc", path],
            output: Process::Redirect::Pipe,
            error: Process::Redirect::Pipe
          )

          content = process.output.gets_to_end
          error = process.error.gets_to_end
          status = process.wait

          if status.success?
            if content.size > 1_000_000
              str << header(path, "Lzip Compressed File", plain)
              str << "[Content too large to display. Size: #{format_size(content.size)}]\n"
            else
              str << header(path, "Lzip Compressed File", plain)
              str << content
            end
          else
            str << "Error: #{error}"
          end
        end
        output
      rescue ex
        "Error reading lzip archive: #{ex.message}"
      end
    end

    # LZMA decompression
    private def self.read_lzma(path : String, plain : Bool) : String
      return "lzma not installed" unless command_exists?("lzma")

      begin
        output = String.build do |str|
          process = Process.new(
            "lzma",
            ["-dc", path],
            output: Process::Redirect::Pipe,
            error: Process::Redirect::Pipe
          )

          content = process.output.gets_to_end
          error = process.error.gets_to_end
          status = process.wait

          if status.success?
            if content.size > 1_000_000
              str << header(path, "LZMA Compressed File", plain)
              str << "[Content too large to display. Size: #{format_size(content.size)}]\n"
            else
              str << header(path, "LZMA Compressed File", plain)
              str << content
            end
          else
            str << "Error: #{error}"
          end
        end
        output
      rescue ex
        "Error reading lzma archive: #{ex.message}"
      end
    end

    # Tar archive listing
    private def self.list_tar(path : String, plain : Bool) : String
      return "tar not installed" unless command_exists?("tar")

      output = String.build do |str|
        str << header(path, "TAR Archive", plain)

        process = Process.new(
          "tar",
          ["-tvf", path],
          output: Process::Redirect::Pipe,
          error: Process::Redirect::Pipe
        )

        content = process.output.gets_to_end
        error = process.error.gets_to_end
        status = process.wait

        if status.success?
          str << format_tar_listing(content, plain)
        else
          str << "Error: #{error}\n"
        end
      end
      output
    rescue ex
      "Error listing tar archive: #{ex.message}"
    end

    # Compressed tar archives
    private def self.list_tar_compressed(path : String, compression : String, plain : Bool) : String
      return "tar not installed" unless command_exists?("tar")

      output = String.build do |str|
        str << header(path, "#{compression.upcase} Compressed TAR Archive", plain)

        process = Process.new(
          "tar",
          ["-tvf", path],
          output: Process::Redirect::Pipe,
          error: Process::Redirect::Pipe
        )

        content = process.output.gets_to_end
        error = process.error.gets_to_end
        status = process.wait

        if status.success?
          str << format_tar_listing(content, plain)
        else
          str << "Error: #{error}\n"
        end
      end
      output
    rescue ex
      "Error listing compressed tar archive: #{ex.message}"
    end

    # ZIP archive listing
    private def self.list_zip(path : String, plain : Bool) : String
      return "unzip not installed" unless command_exists?("unzip")

      format_name = case get_extension(path)
                    when ".ipa" then "IPA (iOS App)"
                    when ".apk" then "APK (Android App)"
                    when ".jar" then "JAR (Java Archive)"
                    when ".war" then "WAR (Web Application Archive)"
                    when ".ear" then "EAR (Enterprise Archive)"
                    else             "ZIP Archive"
                    end

      output = String.build do |str|
        str << header(path, format_name, plain)

        process = Process.new(
          "unzip",
          ["-l", path],
          output: Process::Redirect::Pipe,
          error: Process::Redirect::Pipe
        )

        content = process.output.gets_to_end
        error = process.error.gets_to_end
        status = process.wait

        if status.success?
          str << format_zip_listing(content, plain)
        else
          str << "Error: #{error}\n"
        end
      end
      output
    rescue ex
      "Error listing zip archive: #{ex.message}"
    end

    # RAR archive listing
    private def self.list_rar(path : String, plain : Bool) : String
      if command_exists?("unrar")
        list_rar_unrar(path, plain)
      elsif command_exists?("rar")
        list_rar_rar(path, plain)
      else
        "RAR tools not installed. Install 'unrar' or 'rar'"
      end
    end

    private def self.list_rar_unrar(path : String, plain : Bool) : String
      output = String.build do |str|
        str << header(path, "RAR Archive", plain)

        process = Process.new(
          "unrar",
          ["l", path],
          output: Process::Redirect::Pipe,
          error: Process::Redirect::Pipe
        )

        content = process.output.gets_to_end
        error = process.error.gets_to_end
        status = process.wait

        if status.success?
          str << format_rar_listing(content, plain)
        else
          str << "Error: #{error}\n"
        end
      end
      output
    rescue ex
      "Error listing rar archive: #{ex.message}"
    end

    private def self.list_rar_rar(path : String, plain : Bool) : String
      output = String.build do |str|
        str << header(path, "RAR Archive", plain)

        process = Process.new(
          "rar",
          ["l", path],
          output: Process::Redirect::Pipe,
          error: Process::Redirect::Pipe
        )

        content = process.output.gets_to_end
        error = process.error.gets_to_end
        status = process.wait

        if status.success?
          str << format_rar_listing(content, plain)
        else
          str << "Error: #{error}\n"
        end
      end
      output
    rescue ex
      "Error listing rar archive: #{ex.message}"
    end

    # 7-Zip archive listing
    private def self.list_7z(path : String, plain : Bool) : String
      return "7z not installed" unless command_exists?("7z")

      output = String.build do |str|
        str << header(path, "7-Zip Archive", plain)

        process = Process.new(
          "7z",
          ["l", path],
          output: Process::Redirect::Pipe,
          error: Process::Redirect::Pipe
        )

        content = process.output.gets_to_end
        error = process.error.gets_to_end
        status = process.wait

        if status.success?
          str << format_7z_listing(content, plain)
        else
          str << "Error: #{error}\n"
        end
      end
      output
    rescue ex
      "Error listing 7z archive: #{ex.message}"
    end

    # ISO image listing
    private def self.list_iso(path : String, plain : Bool) : String
      return "isoinfo not installed (install cdrtools or genisoimage)" unless command_exists?("isoinfo")

      output = String.build do |str|
        str << header(path, "ISO Image", plain)

        process = Process.new(
          "isoinfo",
          ["-l", "-i", path],
          output: Process::Redirect::Pipe,
          error: Process::Redirect::Pipe
        )

        content = process.output.gets_to_end
        error = process.error.gets_to_end
        status = process.wait

        if status.success?
          str << format_iso_listing(content, plain)
        else
          str << "Error: #{error}\n"
        end
      end
      output
    rescue ex
      "Error listing iso image: #{ex.message}"
    end

    # IMG/disk image listing
    private def self.list_img(path : String, plain : Bool) : String
      output = String.build do |str|
        str << header(path, "Disk Image", plain)

        stat = File.info(path)
        str << "\n"
        str << format_field("Size", format_size(stat.size), plain)
        str << format_field("Modified", stat.modification_time.to_s, plain)
        str << "\n"

        # Try to detect filesystem type
        if command_exists?("file")
          process = Process.new(
            "file",
            ["-b", path],
            output: Process::Redirect::Pipe,
            error: Process::Redirect::Pipe
          )

          file_type = process.output.gets_to_end.strip
          process.wait

          str << format_field("Type", file_type, plain)
        end

        str << "\n"
        str << colorize("Note: Mount the image to view contents:", :yellow, plain) << "\n"
        str << "  sudo mount -o loop #{shell_escape(path)} /mnt\n"
      end
      output
    rescue ex
      "Error inspecting disk image: #{ex.message}"
    end

    # Formatting helpers
    private def self.header(path : String, type : String, plain : Bool) : String
      output = String.build do |str|
        if plain
          str << "=" * 70 << "\n"
          str << "#{type}: #{path}\n"
          str << "=" * 70 << "\n"
        else
          str << colorize("=" * 70, :cyan, plain) << "\n"
          str << colorize("#{type}: ", :bold_cyan, plain)
          str << colorize(path, :white, plain) << "\n"
          str << colorize("=" * 70, :cyan, plain) << "\n"
        end
      end
      output
    end

    private def self.format_tar_listing(content : String, plain : Bool) : String
      output = String.build do |str|
        str << "\n"
        str << format_table_header(["Permissions", "Owner/Group", "Size", "Date", "Name"], plain)

        content.each_line do |line|
          next if line.strip.empty?
          if line =~ /^([drwx-]+)\s+\S+\s+(\S+\/\S+)\s+(\d+)\s+(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2})\s+(.+)$/
            perms = $1
            owner = $2
            size = format_size($3.to_i64)
            date = $4
            name = $5

            str << format_table_row([perms, owner, size, date, name], plain)
          else
            str << line << "\n"
          end
        end
      end
      output
    end

    private def self.format_zip_listing(content : String, plain : Bool) : String
      output = String.build do |str|
        lines = content.lines
        in_file_list = false

        str << "\n"

        lines.each do |line|
          if line =~ /Length\s+Date\s+Time\s+Name/
            in_file_list = true
            str << format_table_header(["Size", "Date", "Time", "Name"], plain)
            next
          end

          if in_file_list
            if line =~ /^\s*(\d+)\s+(\d{4}-\d{2}-\d{2})\s+(\d{2}:\d{2})\s+(.+)$/
              size = format_size($1.to_i64)
              date = $2
              time = $3
              name = $4

              str << format_table_row([size, date, time, name], plain)
            elsif line =~ /^-+/
              in_file_list = false
            end
          end
        end
      end
      output
    end

    private def self.format_rar_listing(content : String, plain : Bool) : String
      output = String.build do |str|
        str << "\n"
        str << format_table_header(["Size", "Packed", "Ratio", "Date", "Time", "Name"], plain)

        content.each_line do |line|
          if line =~ /^\s*(\d+)\s+(\d+)\s+(\d+)%\s+(\d{2}-\d{2}-\d{2})\s+(\d{2}:\d{2})\s+(.+)$/
            size = format_size($1.to_i64)
            packed = format_size($2.to_i64)
            ratio = $3 + "%"
            date = $4
            time = $5
            name = $6

            str << format_table_row([size, packed, ratio, date, time, name], plain)
          end
        end
      end
      output
    end

    private def self.format_7z_listing(content : String, plain : Bool) : String
      output = String.build do |str|
        lines = content.lines
        in_file_list = false

        str << "\n"

        lines.each do |line|
          if line =~ /Date\s+Time\s+Attr\s+Size\s+Compressed\s+Name/
            in_file_list = true
            str << format_table_header(["Date", "Time", "Size", "Compressed", "Name"], plain)
            next
          end

          if in_file_list
            if line =~ /^(\d{4}-\d{2}-\d{2})\s+(\d{2}:\d{2}:\d{2})\s+[.D]+\s+(\d+)\s+(\d+)?\s+(.+)$/
              date = $1
              time = $2
              size = format_size($3.to_i64)
              compressed = $4 ? format_size($4.to_i64) : "-"
              name = $5

              str << format_table_row([date, time, size, compressed, name], plain)
            elsif line =~ /^-+/
              in_file_list = false
            end
          end
        end
      end
      output
    end

    private def self.format_iso_listing(content : String, plain : Bool) : String
      output = String.build do |str|
        str << "\n"

        content.each_line do |line|
          if line =~ /^Directory listing of (.+)$/
            str << "\n" << colorize("Directory: #{$1}", :bold_blue, plain) << "\n\n"
          elsif line =~ /^-(.{9})\s+\d+\s+\d+\s+(\d+)\s+\[\s*\d+\]\s+(.+)$/
            perms = $1
            size = format_size($2.to_i64)
            name = $3

            str << format_field("  #{name}", "#{perms}  #{size}", plain)
          end
        end
      end
      output
    end

    private def self.format_table_header(columns : Array(String), plain : Bool) : String
      if plain
        columns.join("  |  ") + "\n" + ("-" * (columns.sum(&.size) + (columns.size - 1) * 5)) + "\n"
      else
        colorize(columns.join("  │  "), :bold_cyan, plain) + "\n" +
          colorize("─" * (columns.sum(&.size) + (columns.size - 1) * 5), :cyan, plain) + "\n"
      end
    end

    private def self.format_table_row(columns : Array(String), plain : Bool) : String
      if plain
        columns.join("  |  ") + "\n"
      else
        columns.join("  │  ") + "\n"
      end
    end

    private def self.format_field(label : String, value : String, plain : Bool) : String
      if plain
        "#{label}: #{value}\n"
      else
        "#{colorize(label, :cyan, plain)}: #{value}\n"
      end
    end

    private def self.colorize(text : String, color : Symbol, plain : Bool) : String
      return text if plain

      case color
      when :cyan
        "\e[36m#{text}\e[0m"
      when :bold_cyan
        "\e[1;36m#{text}\e[0m"
      when :blue
        "\e[34m#{text}\e[0m"
      when :bold_blue
        "\e[1;34m#{text}\e[0m"
      when :yellow
        "\e[33m#{text}\e[0m"
      when :white
        "\e[37m#{text}\e[0m"
      else
        text
      end
    end

    private def self.format_size(bytes : Int64) : String
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

    private def self.command_exists?(command : String) : Bool
      Process.run("which", [command], output: Process::Redirect::Close, error: Process::Redirect::Close).success?
    end

    private def self.shell_escape(path : String) : String
      "'" + path.gsub("'", "'\\''") + "'"
    end
  end
end
