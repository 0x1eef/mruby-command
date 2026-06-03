# frozen_string_literal: true

load File.join(__dir__, "mrblib", "command", "version.rb")

MRuby::Gem::Specification.new("mruby-command") do |spec|
  spec.license = "0BSD"
  spec.authors = "0x1eef"
  spec.version = Command::VERSION
  spec.description = "An object-oriented interface for spawning a command"

  spec.add_dependency "mruby-process", github: "0x1eef/mruby-process", branch: "main"
  spec.add_dependency "mruby-io",      github: "iij/mruby-io"
  spec.add_dependency "mruby-struct",  github: "iij/mruby-struct"
  spec.add_dependency "mruby-errno",   github: "iij/mruby-errno"
  spec.rbfiles = [
    File.join(__dir__, "mrblib", "command.rb"),
    File.join(__dir__, "mrblib", "command", "version.rb")
  ]

  if ENV["BUILD"] == "test"
    spec.add_dependency "mruby-minitest", github: "0x1eef/mruby-minitest", branch: "main"
  end
end
