MRuby::Build.new("mruby-command") do |conf|
  profile = ENV.fetch("BUILD_PROFILE", "test")
  source_root = File.expand_path("..", __dir__)

  conf.toolchain
  conf.gembox "default"

  case profile
  when "test", "developer"
    conf.enable_debug
    ENV["ENV"] = "TEST"
  when "production"
    conf.cc.flags << "-DNDEBUG"
  else
    raise ArgumentError, "unknown BUILD_PROFILE=#{profile.inspect}"
  end

  conf.gem File.expand_path(__dir__)
end
