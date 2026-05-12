##
# Command provides an object-oriented interface for spawning
# a command on UNIX-like operating systems.
#
# It captures stdout, stderr, and the exit status of the
# spawned process, and offers callbacks for success and
# failure outcomes.
#
# @example
#   Command.new("ruby", "-e", "exit 0")
#     .success { |cmd| print "OK: pid=#{cmd.pid}" }
#     .failure { |cmd| print "FAIL: status=#{cmd.exit_status}" }
class Command
  ##
  # @api private
  Pipe = Struct.new(:r, :w) do
    def self.pair
      new(*IO.pipe)
    end

    def close
      [r, w].each(&:close)
    end
  end

  ##
  # @param [String] cmd
  #  A command to spawn
  # @param [Array<String>] argv
  #  Zero or more command-line arguments
  # @return [Command]
  def initialize(cmd, *argv)
    @cmd = cmd
    @argv = argv.dup
    @status = nil
    @spawned = false
    @stdout = "".b
    @stderr = "".b
    @enoent = false
  end

  ##
  # @param [Array<String, #to_s>] argv
  #  Command-line arguments
  # @return [Command]
  def argv(*argv)
    tap { @argv.concat(argv) }
  end

  ##
  # Spawns a command, captures its output and waits for it
  # to finish.
  # @return [Command]
  def spawn
    return self if @spawned
    @spawned = true
    out = Pipe.pair
    err = Pipe.pair
    @pid = fork_and_capture(out, err)
    out.w.close
    err.w.close
    read_output(out, err)
    Process.waitpid(@pid)
    @status = $?
    self
  ensure
    out&.close
    err&.close
  end

  ##
  # @return [Process::Status, nil]
  def status
    spawn
    @status
  end

  ##
  # @return [Integer, nil]
  def pid
    (s = status)&.pid
  end

  ##
  # @return [Integer, nil]
  def exit_status
    (s = status)&.exitstatus
  end
  alias_method :exitstatus, :exit_status

  ##
  # @group IO

  ##
  # @return [String]
  def stdout
    spawn
    @stdout
  end

  ##
  # @return [String]
  def stderr
    spawn
    @stderr
  end
  # @endgroup

  ##
  # @group Predicates

  ##
  # @return [Boolean]
  def success?
    (s = status)&.success? || false
  end

  ##
  # @return [Boolean]
  def spawned?
    @spawned
  end

  ##
  # @return [Boolean]
  def command_not_found?
    spawn
    @enoent
  end
  alias_method :not_found?, :command_not_found?
  # @endgroup

  ##
  # @group Callbacks

  ##
  # @yieldparam [Command] cmd
  # @return [Command]
  def success
    tap do
      spawn
      yield(self) if (s = status)&.success?
    end
  end

  ##
  # @yieldparam [Command] cmd
  # @return [Command]
  def failure
    tap do
      spawn
      s = status
      yield(self) if s.nil? || !s.success?
    end
  end
  # @endgroup

  private

  ##
  # Forks a child process, redirects its stdout and stderr
  # to the given pipes, and runs the command via system.
  # Falls back to "false" when the command is not found.
  # @param [Command::Pipe] out
  # @param [Command::Pipe] err
  # @return [Integer] child pid
  def fork_and_capture(out, err)
    fork do
      $stdout.reopen(out.w)
      $stderr.reopen(err.w)
      [out.r, err.r].each(&:close)
      unless system("#{shellescape(@cmd)} #{@argv.map { shellescape(_1) }.join(' ')}")
        @exit_code = $?.exitstatus
      end
      exit!(@exit_code || 0)
    end
  rescue Errno::ENOENT
    @cmd = "false"
    @argv = []
    @stderr = "No such file or directory - #{@cmd}"
    @enoent = true
    fork do
      exit!(1)
    end
  end

  ##
  # Reads stdout and stderr from the pipes until both
  # reach EOF.
  # @param [Command::Pipe] out
  # @param [Command::Pipe] err
  # @return [void]
  def read_output(out, err)
    readers = [out.r, err.r]
    loop do
      ready, = IO.select(readers, nil, nil, 0.01)
      if ready
        ready.each do |fd|
          buf = fd.readpartial(4096)
          if fd == out.r
            @stdout << buf
          else
            @stderr << buf
          end
        rescue EOFError
          readers.delete(fd)
        end
      end
      break if readers.empty?
    end
  end

  ##
  # Shell-escapes a string for use in system().
  # @param [String] s
  # @return [String]
  def shellescape(s)
    "'" + s.to_s.gsub("'", %q('"'"')) + "'"
  end
end
