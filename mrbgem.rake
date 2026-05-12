# frozen_string_literal: true

MRuby::Gem::Specification.new("mruby-command") do |spec|
  spec.license = "0BSD"
  spec.authors = "0x1eef"
  spec.version = "0.1.0"
  spec.description = "An object-oriented interface for spawning a command"

  spec.add_dependency "mruby-process",   github: "iij/mruby-process"
  spec.add_dependency "mruby-io",        github: "iij/mruby-io"
  spec.add_dependency "mruby-thread",    github: "mattn/mruby-thread"
  spec.add_dependency "mruby-struct",    github: "iij/mruby-struct"
  spec.add_dependency "mruby-errno",     github: "iij/mruby-errno"

  spec.rbfiles = Dir[File.expand_path("mrblib/*.rb", __dir__)].sort
end
