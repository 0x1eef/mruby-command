# frozen_string_literal: true

describe "Command" do
  describe "#initialize" do
    it "sets the command and arguments" do
      cmd = Command.new("echo", "hello")
      expect(cmd.spawned?).must_equal false
    end

    it "accepts no arguments" do
      cmd = Command.new("true")
      expect(cmd.spawned?).must_equal false
    end
  end

  describe "#argv" do
    it "adds arguments" do
      cmd = Command.new("echo").argv("hello", "world")
      cmd.spawn
      expect(cmd.stdout).must_include "hello world"
    end

    it "returns self for chaining" do
      cmd = Command.new("echo").argv("hello")
      expect(cmd.argv("world")).must_be_same_as cmd
    end
  end

  describe "#spawn" do
    it "spawns a command" do
      cmd = Command.new("true")
      expect(cmd.spawned?).must_equal false
      cmd.spawn
      expect(cmd.spawned?).must_equal true
    end

    it "idempotently spawns" do
      cmd = Command.new("true")
      cmd.spawn
      cmd.spawn
      expect(cmd.spawned?).must_equal true
    end

    it "returns self" do
      cmd = Command.new("true")
      expect(cmd.spawn).must_be_same_as cmd
    end
  end

  describe "#status" do
    it "returns the process status" do
      cmd = Command.new("true")
      expect(cmd.status).must_be_instance_of Process::Status
    end

    it "returns nil before spawning" do
      cmd = Command.new("true")
      expect(cmd.instance_variable_get(:@status)).must_be_nil
    end

    it "triggers spawn" do
      cmd = Command.new("true")
      expect(cmd.spawned?).must_equal false
      cmd.status
      expect(cmd.spawned?).must_equal true
    end
  end

  describe "#pid" do
    it "returns the process ID" do
      cmd = Command.new("true")
      expect(cmd.pid).must_be_kind_of Integer
    end

    it "returns nil before spawning" do
      cmd = Command.new("true")
      expect(cmd.pid).must_be_nil
    end
  end

  describe "#exit_status" do
    it "returns 0 for a successful command" do
      cmd = Command.new("true")
      expect(cmd.exit_status).must_equal 0
    end

    it "returns 1 for a failing command" do
      cmd = Command.new("false")
      expect(cmd.exit_status).must_equal 1
    end

    it "returns nil before spawning" do
      cmd = Command.new("true")
      expect(cmd.exit_status).must_be_nil
    end
  end

  describe "#exitstatus" do
    it "is an alias for exit_status" do
      cmd = Command.new("true")
      expect(cmd.exitstatus).must_equal cmd.exit_status
    end
  end

  describe "#stdout" do
    it "captures stdout" do
      cmd = Command.new("echo", "hello")
      expect(cmd.stdout).must_equal "hello\n"
    end

    it "captures multiline output" do
      cmd = Command.new("echo", "hello\nworld")
      expect(cmd.stdout).must_equal "hello\nworld\n"
    end

    it "triggers spawn" do
      cmd = Command.new("true")
      expect(cmd.spawned?).must_equal false
      cmd.stdout
      expect(cmd.spawned?).must_equal true
    end
  end

  describe "#stderr" do
    it "captures stderr" do
      cmd = Command.new("sh", "-c", "echo hello >&2")
      expect(cmd.stderr).must_equal "hello\n"
    end

    it "triggers spawn" do
      cmd = Command.new("true")
      expect(cmd.spawned?).must_equal false
      cmd.stderr
      expect(cmd.spawned?).must_equal true
    end
  end

  describe "#success?" do
    it "returns true when exit status is 0" do
      cmd = Command.new("true")
      expect(cmd.success?).must_equal true
    end

    it "returns false when exit status is non-zero" do
      cmd = Command.new("false")
      expect(cmd.success?).must_equal false
    end

    it "triggers spawn" do
      cmd = Command.new("true")
      expect(cmd.spawned?).must_equal false
      cmd.success?
      expect(cmd.spawned?).must_equal true
    end
  end

  describe "#spawned?" do
    it "returns false before spawn" do
      cmd = Command.new("true")
      expect(cmd.spawned?).must_equal false
    end

    it "returns true after spawn" do
      cmd = Command.new("true")
      cmd.spawn
      expect(cmd.spawned?).must_equal true
    end
  end

  describe "#command_not_found?" do
    it "returns false for an existing command" do
      cmd = Command.new("true")
      expect(cmd.command_not_found?).must_equal false
    end

    it "returns true for a non-existent command" do
      cmd = Command.new("./this-command-does-not-exist")
      expect(cmd.command_not_found?).must_equal true
    end

    it "is aliased as not_found?" do
      cmd = Command.new("./this-command-does-not-exist")
      expect(cmd.not_found?).must_equal true
    end

    it "sets stderr to the error message" do
      cmd = Command.new("./this-command-does-not-exist")
      cmd.command_not_found?
      expect(cmd.stderr).must_include "No such file or directory"
    end
  end

  describe "#success callback" do
    it "yields the command on success" do
      yielded = nil
      cmd = Command.new("true").success { |c| yielded = c }
      expect(yielded).must_be_same_as cmd
    end

    it "does not yield on failure" do
      yielded = nil
      Command.new("false").success { |c| yielded = c }
      expect(yielded).must_be_nil
    end

    it "returns self for chaining" do
      cmd = Command.new("true")
      expect(cmd.success { }).must_be_same_as cmd
    end
  end

  describe "#failure callback" do
    it "yields the command on failure" do
      yielded = nil
      cmd = Command.new("false").failure { |c| yielded = c }
      expect(yielded).must_be_same_as cmd
    end

    it "does not yield on success" do
      yielded = nil
      Command.new("true").failure { |c| yielded = c }
      expect(yielded).must_be_nil
    end

    it "returns self for chaining" do
      cmd = Command.new("false")
      expect(cmd.failure { }).must_be_same_as cmd
    end
  end

  describe "chaining" do
    it "chains success and failure" do
      out = []
      Command.new("true")
        .success { out << :success }
        .failure { out << :failure }
      expect(out).must_equal [:success]
    end

    it "chains both paths" do
      out = []
      Command.new("false")
        .success { out << :success }
        .failure { out << :failure }
      expect(out).must_equal [:failure]
    end
  end
end

Minitest.run(ARGV) || exit(1)
