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
  HAS_MRUBY_TASK = Object.const_defined?(:Task)

  ##
  # @api private
  Pipe = Struct.new(:r, :w) do
    def self.pair
      new(*IO.pipe)
    end

    def close
      [r, w].each do |io|
        io.close unless io.closed?
      end
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
    spawn_with_fallback(out, err)
    out.w.close
    err.w.close
    read_output(out, err)
    until Process.waitpid(@pid, Process::WNOHANG)
      HAS_MRUBY_TASK ? sleep_ms(1) : sleep(0.01)
    end
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
  # Spawns the command, falling back to "false" if the
  # command is not found.
  # @param [Command::Pipe] out
  # @param [Command::Pipe] err
  # @return [void]
  def spawn_with_fallback(out, err)
    begin
      @pid = Process.spawn(@cmd, *@argv, out: out.w, err: err.w)
    rescue Errno::ENOENT => ex
      @cmd = "false"
      @argv = []
      @stderr = ex.message
      @enoent = true
      @pid = Process.spawn("false")
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
      ready, = IO.select(readers, nil, nil, HAS_MRUBY_TASK ? 0 : 0.01)
      if ready
        ready.each do |fd|
          buf = fd.sysread(4096)
          if fd == out.r
            @stdout << buf
          else
            @stderr << buf
          end
        rescue EOFError, IOError
          readers.delete(fd)
        end
      else
        HAS_MRUBY_TASK and Task.pass
      end
      break if readers.empty?
    end
  end
end
