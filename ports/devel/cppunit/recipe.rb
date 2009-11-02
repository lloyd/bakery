
{
  :url => "http://prdownloads.sourceforge.net/cppunit/cppunit-1.12.1.tar.gz",
  :md5 => "bd30e9cf5523cdfc019b94f5e1d7fd19",
  :configure => {
    [ :Linux, :MacOSX ] => lambda { |c|
      puts "Building #{c[:build_type].to_s} bits..."
      ldflags = ""
      cflags = c[:build_type] == :debug ? "-g -O0" : ""
      if c[:platform] == :Darwin
        cflags += $darwinCompatCompileFlags
      end
      cfgScript = File.join(c[:src_dir], "configure")
      configCmd = "#{cfgScript} --enable-static --disable-shared"
      configCmd += " --prefix=#{c[:output_dir]} --disable-doxygen"
      configCmd += " CXXFLAGS=\"#{cflags}\""
      if $platform == :Darwin
        configCmd += " LDFLAGS=\"#{$darwinCompatLinkFlags}\""
      end
      system(configCmd)
    }
  },
  :build => {
    [ :Linux, :MacOSX ] => "make",
    :Windows => lambda { |c|
      Dir.chdir(File.join(c[:src_dir], "src")) { 
        buildType = c[:build_type].to_s
        system("devenv CppUnitLibraries.sln /build \"#{buildType} static\"")
      }
    }
  },
  :install => {
    [ :Linux, :MacOSX ] => lambda { |c|
      system("make install")

      # now move built libraries down into a build type specific dir
      Dir.glob(File.join(c[:output_dir], "lib", "*cppunit*")).each { |f|
        FileUtils.mv(f, c[:output_lib_dir], :verbose => true)
      }
    },
    :Windows => lambda { |c|
      # install static lib
      puts "installing #{c[:build_type].to_s} static library..."
      libTrailer = (c[:build_type] == :debug) ? "d" : ""

      FileUtils.cp(File.join(c[:build_dir], "lib", "cppunit#{libTrailer}.lib"),
                   File.join(c[:output_lib_dir], "cppunit.lib"),
                   :verbose => true)

      # install headers
      puts "installing headers..."
      Dir.glob(File.join(File.join(c[:src_dir], "include", "cppunit", "*"))).each { |h| 
        FileUtils.cp_r(h, c[:output_inc_dir], :verbose => true)
      }
    }
  }
}
