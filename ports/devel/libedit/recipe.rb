{
  :url => "http://www.thrysoee.dk/editline/libedit-20090722-3.0.tar.gz",
  :md5 => "379afe3fa302e41fc3cb82ad5c969596",
  :configure => {
    [ :Linux, :MacOSX ] => lambda { |c|
      if $platform == :MacOSX
        ENV['CFLAGS'] = ENV['CFLAGS'].to_s + $darwinCompatCompileFlags
        ENV['CXXFLAGS'] = ENV['CXXFLAGS'].to_s + $darwinCompatCompileFlags
      end

      if c[:build_type] == :debug
        ENV['CFLAGS'] = ENV['CFLAGS'].to_s + " -g -O0"
      end

      configScript = File.join(c[:src_dir], "configure")
      configstr = "#{configScript} --disable-shared --prefix=#{c[:output_dir]}"
      puts "running configure: #{configstr}"
      system(configstr)
    }
  },
  :build => {
    [ :Linux, :MacOSX ] => "make"
  },
  :install => {
    [ :Linux, :MacOSX ] => lambda { |c|
      system("make install")

      # XXX: consider installing to build dir then copying into output?
      # (less cruft)
      # rename static lib (append _s and move to buildtype dir)
      lib_dir = File.join(c[:output_dir], "lib", c[:build_type].to_s)
      puts "creating '#{lib_dir}'"
      FileUtils.mkdir_p(lib_dir)
      FileUtils.mv(File.join(c[:output_dir], "lib", "libedit.a"),
                   File.join(lib_dir, "libedit_s.a"),
                   :verbose => true)

      # mv headers
      # XXX: shall we tuck headers under a libedit directory?
#      FileUtils.cp("#{buildDir}/lib/libedit.a",
#                   "#{$libInstallDir}/#{buildType}/libedit_s.a",
#                   :verbose => $verbose)
    }
  }
}
