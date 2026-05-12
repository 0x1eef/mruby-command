<p align="center">
  <a href="mruby-command"><img src="https://github.com/llmrb/llm.rb/raw/main/llm.png" width="200" height="200" border="0" alt="mruby-command"></a>
</p>

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

## License

[BSD Zero Clause](https://choosealicense.com/licenses/0bsd/)
<br>
See [LICENSE](./LICENSE)
