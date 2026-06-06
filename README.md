## About

mruby-command provides Go-inspired, non-blocking commands
that work well with mruby's cooperative scheduler (mruby-task).
Loosely based on CRuby's [test-cmd.rb](https://github.com/0x1eef/test-cmd.rb),
although the two projects have diverged over time.

## Quick start

#### Spawn

Spawn a command and collect its output and exit status:

```ruby
cmd = Command.new("echo", "hello")
puts cmd.stdout  # => "hello\n"
```

#### Callbacks

Success and failure callbacks provide hooks for when a command
exits successfully or unsuccessfully:

```ruby
Command.new("ruby", "-e", "exit 0")
  .success { |cmd| print "Command [#{cmd.pid}] was successful\n" }
  .failure { |cmd| print "Command [#{cmd.pid}] was unsuccessful\n" }

Command.new("ruby", "-e", "exit 42")
  .success { |cmd| print "unreachable\n" }
  .failure { |cmd| print "Command [#{cmd.pid}] failed\n" }
```

#### Exit status

```ruby
cmd = Command.new("ruby", "-e", "exit 42")
puts cmd.exit_status  # => 42
puts cmd.success?     # => false
```

#### Command not found

When the command is not found, failure callbacks still fire
and `command_not_found?` returns true:

```ruby
cmd = Command.new("nonexistent")
puts cmd.command_not_found?  # => true
```

## Features

**Command.new(cmd, \*argv)** <br>
Creates a new command object with the given command and optional
arguments. The command is not spawned until one of the output,
status, or callback methods is called.

**Command#spawn** <br>
Spawns the command, captures stdout and stderr, and waits for the
process to finish. Called automatically by methods that need output
or exit status.

**Command#stdout** <br>
Returns the captured stdout output as a string.

**Command#stderr** <br>
Returns the captured stderr output as a string.

**Command#pid** <br>
Returns the process ID of the spawned command.

**Command#exit_status** <br>
Returns the exit status of the command, or nil if the command has
not been spawned yet.

**Command#success?** <br>
Returns true if the command exited with a zero status.

**Command#command_not_found?** <br>
Returns true if the command could not be found.

**Command#success** <br>
Accepts a block that is called when the command exits successfully.

**Command#failure** <br>
Accepts a block that is called when the command exits unsuccessfully.

**Command#argv** <br>
Appends arguments to the command.

## Integration

Add to your mruby build config:

```ruby
MRuby::Build.new("app") do |conf|
  conf.toolchain
  conf.gembox "default"
  conf.gem github: "0x1eef/mruby-command", branch: "main"
end
```

Dependencies are declared in [mrbgem.rake](mrbgem.rake) and resolved
automatically by the mruby build system:

| Dependency | Purpose |
|---|---|
| [mruby-process](https://github.com/iij/mruby-process) | Process.spawn, Process.waitpid, $? |
| [mruby-io](https://github.com/iij/mruby-io) | IO.pipe, IO.select |
| [mruby-struct](https://github.com/iij/mruby-struct) | Command::Pipe (Struct) |
| [mruby-errno](https://github.com/iij/mruby-errno) | Errno::ENOENT handling |

## License

[BSD Zero Clause](https://choosealicense.com/licenses/0bsd/)
<br>
See [LICENSE](./LICENSE)
