## About

mruby-command provides an object-oriented interface for spawning
a command on UNIX-like operating systems. It is an mruby port
of [test-cmd.rb](https://github.com/0x1eef/test-cmd.rb).

## Examples

### Callbacks

Success and failure callbacks provide hooks for when
a command exits successfully or unsuccessfully:

```ruby
Command.new("ruby", "-e", "exit 0")
  .success { |cmd| print "Command [#{cmd.pid}] was successful\n" }
  .failure { |cmd| print "Command [#{cmd.pid}] was unsuccessful\n" }
```

### Capturing output

```ruby
cmd = Command.new("echo", "hello")
puts cmd.stdout  # => "hello\n"
```

### Checking exit status

```ruby
cmd = Command.new("ruby", "-e", "exit 42")
puts cmd.exit_status  # => 42
puts cmd.success?     # => false
```

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
