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
  # to finish. I/O and process wait are interleaved via
  # IO.select so no background thread is needed.
  #
  # @return [Command]
  def spawn
    return self if @spawned
    tap do
      @spawned = true
      out_r, out_w = IO.pipe
      err_r, err_w = IO.pipe

      begin
        pid = Process.spawn(@cmd, *@argv, out: out_w, err: err_w)
      rescue Errno::ENOENT => ex
        @cmd = "false"
        @argv = []
        @stderr = ex.message
        @enoent = true
        pid = Process.spawn("false")
      end

      out_w.close
      err_w.close

      readers = [out_r, err_r]
      loop do
        ready, = IO.select(readers, nil, nil, 0.01)
        if ready
          ready.each do |fd|
            buf = fd.readpartial(4096)
            if fd == out_r
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

      Process.waitpid(pid)
      @status = $?
    end
  end

  ##
  # @return [Process::Status, nil]
  #  Returns the status of a process
  def status
    spawn
    @status
  end

  ##
  # @return [Integer, nil]
  #  Returns the process ID of a spawned command
  def pid
    s = status
    s&.pid
  end

  ##
  # @return [Integer, nil]
  #  Returns the exit status of a process
  def exit_status
    s = status
    s&.exitstatus
  end
  alias_method :exitstatus, :exit_status

  ##
  # @group IO

  ##
  # @return [String]
  #  Returns the contents of stdout
  def stdout
    spawn
    @stdout
  end

  ##
  # @return [String]
  #  Returns the contents of stderr
  def stderr
    spawn
    @stderr
  end
  # @endgroup

  ##
  # @group Predicates

  ##
  # @return [Boolean]
  #  Returns true when a command exited successfully
  def success?
    s = status
    s&.success? || false
  end

  ##
  # @return [Boolean]
  #  Returns true when a command has been spawned
  def spawned?
    @spawned
  end

  ##
  # @return [Boolean]
  #  Returns true when a command can't be found
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
  #  Yields an instance of {Command}
  # @return [Command]
  def success
    tap do
      spawn
      s = status
      yield(self) if s&.success?
    end
  end

  ##
  # @yieldparam [Command] cmd
  #  Yields an instance of {Command}
  # @return [Command]
  def failure
    tap do
      spawn
      s = status
      yield(self) if s.nil? || !s.success?
    end
  end
  # @endgroup
end
