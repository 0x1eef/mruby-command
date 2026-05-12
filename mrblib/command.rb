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
    @out_r, @out_w = IO.pipe
    @err_r, @err_w = IO.pipe
    spawn_with_fallback
    @out_w.close
    @err_w.close
    read_output
    wait_for_exit
    self
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
  # @return [void]
  def spawn_with_fallback
    begin
      @pid = Process.spawn(@cmd, *@argv, out: @out_w, err: @err_w)
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
  # @return [void]
  def read_output
    readers = [@out_r, @err_r]
    loop do
      ready, = IO.select(readers, nil, nil, 0.01)
      if ready
        ready.each do |fd|
          buf = fd.readpartial(4096)
          if fd == @out_r
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
  # Waits for the spawned process to exit and captures
  # its status.
  # @return [void]
  def wait_for_exit
    Process.waitpid(@pid)
    @status = $?
  end
end
