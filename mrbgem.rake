# frozen_string_literal: true

MRuby::Gem::Specification.new("mruby-command") do |spec|
  spec.license = "0BSD"
  spec.authors = "0x1eef"
  spec.version = "0.1.0"
  spec.description = "An object-oriented interface for spawning a command"

  spec.add_dependency "mruby-process", github: "0x1eef/mruby-process", branch: "main"
  spec.add_dependency "mruby-io",      github: "iij/mruby-io"
  spec.add_dependency "mruby-struct",  github: "iij/mruby-struct"
  spec.add_dependency "mruby-errno",   github: "iij/mruby-errno"

  if ENV["ENV"] == "TEST"
    spec.add_dependency "mruby-minitest", github: "0x1eef/mruby-minitest", branch: "main"
    spec.rbfiles.concat Dir[File.expand_path("spec/*.rb", __dir__)].sort
  end

  spec.rbfiles = Dir[File.expand_path("mrblib/*.rb", __dir__)].sort
end
