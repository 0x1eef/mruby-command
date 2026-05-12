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
  class Pipe < Struct.new(:r, :w)
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
  # Spawns a command
  # @return [Command]
  def spawn
    return self if @spawned
    tap do
      @spawned = true
      out = Pipe.pair
      err = Pipe.pair
      thread = produce(out, err)
      consume(thread, out, err)
    ensure
      out&.close
      err&.close
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

  private

  ##
  # @param [Command::Pipe] out
  #  A pipe for stdout
  # @param [Command::Pipe] err
  #  A pipe for stderr
  # @return [Thread]
  #  Returns a thread for a spawned command
  def produce(out, err)
    Thread.new do
      begin
        pid = Process.spawn(@cmd, *@argv, out: out.w, err: err.w)
        out.w.close
        err.w.close
        Process.wait(pid)
        @status = $?
      rescue Errno::ENOENT => ex
        @cmd = "false"
        @argv = []
        @stderr = ex.message
        @enoent = true
        pid = Process.spawn("false")
        Process.wait(pid)
        @status = $?
      end
    end
  end

  ##
  # @param [Thread] thread
  #  A thread for a spawned command
  # @param [Command::Pipe] out
  #  A pipe for stdout
  # @param [Command::Pipe] err
  #  A pipe for stderr
  # @return [void]
  def consume(thread, out, err)
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
      break unless thread.alive? || IO.select(readers, nil, nil, 0.01)
    end
  end
end
