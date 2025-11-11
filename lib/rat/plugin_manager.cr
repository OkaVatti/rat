require "json"
require "http/client"

module Rat
  class Plugin
    include JSON::Serializable

    property name : String
    property version : String
    property executable : String
    property file_types : Array(String)
    property description : String?

    def initialize(@name, @version, @executable, @file_types, @description = nil)
    end
  end

  class PluginManager
    @plugins : Array(Plugin)
    @plugin_dir : String

    def initialize
      @plugin_dir = File.join(ENV["HOME"]? || "", ".config", "rat", "plugins")
      @plugins = [] of Plugin
      load_plugins
    end

    def load_plugins
      return unless Dir.exists?(@plugin_dir)

      Dir.glob(File.join(@plugin_dir, "*.json")).each do |config_file|
        begin
          content = File.read(config_file)
          plugin = Plugin.from_json(content)
          @plugins << plugin if validate_plugin(plugin)
        rescue ex
          STDERR.puts "Warning: Failed to load plugin from #{config_file}: #{ex.message}"
        end
      end
    end

    def find_plugin(path : String) : Plugin?
      ext = File.extname(path).downcase
      @plugins.find { |p| p.file_types.includes?(ext) }
    end

    def execute_plugin(plugin : Plugin, path : String, content : String) : String?
      executable = File.join(@plugin_dir, plugin.executable)
      return nil unless File.exists?(executable)

      request = {
        "jsonrpc" => "2.0",
        "method"  => "render",
        "params"  => {
          "path"    => path,
          "content" => content,
        },
        "id" => 1,
      }.to_json

      begin
        io = IO::Memory.new(request)
        process = Process.new(
          executable,
          input: io,
          output: Process::Redirect::Pipe,
          error: Process::Redirect::Pipe
        )

        output = process.output.gets_to_end
        error = process.error.gets_to_end
        status = process.wait

        if status.success?
          response = JSON.parse(output)
          if result = response["result"]?
            return result.as_s
          end
        else
          STDERR.puts "Plugin error: #{error}"
        end
      rescue ex
        STDERR.puts "Failed to execute plugin #{plugin.name}: #{ex.message}"
      end

      nil
    end

    private def validate_plugin(plugin : Plugin) : Bool
      executable = File.join(@plugin_dir, plugin.executable)

      unless File.exists?(executable)
        STDERR.puts "Warning: Plugin #{plugin.name} executable not found: #{executable}"
        return false
      end

      unless File.executable?(executable)
        STDERR.puts "Warning: Plugin #{plugin.name} executable is not executable: #{executable}"
        return false
      end

      true
    end

    def list_plugins : Array(Plugin)
      @plugins
    end
  end
end
