require "ssh2"
require "socket"

module Rat
  class SSHClient
    @session : SSH2::Session?
    @host : String
    @port : Int32
    @user : String
    @key_path : String?
    @password : String?

    def initialize(@host : String, @port : Int32, @user : String, @key_path : String? = nil, @password : String? = nil)
    end

    def self.parse_location(location : String) : Tuple(String, String, Int32)
      parts = location.split(":")
      if parts.size < 2
        raise "Invalid SSH location format. Expected user@host:port"
      end

      user_host = parts[0]
      port = parts[1]?.try(&.to_i32) || 22

      user_host_parts = user_host.split("@")
      if user_host_parts.size != 2
        raise "Invalid SSH location format. Expected user@host:port"
      end

      user = user_host_parts[0]
      host = user_host_parts[1]

      {user, host, port}
    end

    def connect
      socket = TCPSocket.new(@host, @port)
      @session = SSH2::Session.new(socket)
      session = @session.not_nil!
      session.handshake

      if key_path = @key_path
        unless File.exists?(key_path)
          raise "SSH key not found: #{key_path}"
        end

        pubkey_path = key_path + ".pub"
        unless File.exists?(pubkey_path)
          raise "Public key not found: #{pubkey_path}. Ensure your public key exists alongside the private key."
        end

        session.login_with_pubkey(@user, key_path, pubkey_path)
      elsif password = @password
        session.login(@user, password)
      else
        print "Password for #{@user}@#{@host}: "
        STDIN.noecho do
          pass = STDIN.gets.to_s.chomp
          puts ""
          session.login(@user, pass)
        end
      end
    end

    # Read a remote file via `cat` executed on a remote channel.
    def read_file(remote_path : String) : String
      session = @session
      raise "Not connected to SSH server" unless session

      output = "" # build by concatenation

      channel = session.open_session
      begin
        channel.command("cat #{shell_escape(remote_path)}")

        # 16 KiB buffer
        buf = Bytes.new(16_384)
        slice = buf.to_slice

        while true
          n = begin
            channel.read(slice)
          rescue
            nil
          end

          break if n.nil? || n <= 0
          # convert only the read portion to string and append
          output = output + String.new(slice[0, n])
        end

        channel.wait_eof rescue nil
        channel.wait_closed rescue nil
      ensure
        channel.close rescue nil
      end

      output
    end

    # Check if a remote file exists (returns true if "exists" echoed)
    def file_exists?(remote_path : String) : Bool
      session = @session
      return false unless session

      result = "" # build by concatenation

      channel = session.open_session
      begin
        channel.command("test -f #{shell_escape(remote_path)} && echo exists || true")

        buf = Bytes.new(8_192)
        slice = buf.to_slice

        while true
          n = begin
            channel.read(slice)
          rescue
            nil
          end

          break if n.nil? || n <= 0
          result = result + String.new(slice[0, n])
        end

        channel.wait_eof rescue nil
        channel.wait_closed rescue nil
      ensure
        channel.close rescue nil
      end

      result.strip == "exists"
    end

    def close
      @session.try(&.disconnect)
      @session = nil
    end

    private def shell_escape(path : String) : String
      "'" + path.gsub("'", "'\\''") + "'"
    end
  end
end
