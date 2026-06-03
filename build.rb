MRuby::Build.new("mruby-command") do |conf|
  profile = ENV.fetch("BUILD", "test")
  source_root = File.expand_path("..", __dir__)

  conf.toolchain
  conf.gembox "default"
  conf.gem "."

  case profile
  when "test", "developer"
    conf.enable_debug
  when "production"
    conf.cc.flags << "-DNDEBUG"
  else
    raise ArgumentError, "unknowwn BUILD=#{profile.inspect}"
  end
end
