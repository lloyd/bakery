
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
      lib_dir = File.join(c[:output_dir], "lib", c[:build_type].to_s)
      FileUtils.mkdir_p(lib_dir)
      Dir.glob(File.join(c[:output_dir], "lib", "*cppunit*")).each { |f|
        FileUtils.mv(f, lib_dir, :verbose => true)
      }
    },
    :Windows => lambda { |c|
      # install static lib
      puts "installing #{c[:build_type].to_s} static library..."
      libTrailer = (c[:build_type] == :debug) ? "d" : ""

      lib_dir = File.join(c[:output_dir], "lib", c[:build_type].to_s)
      FileUtils.mkdir_p(lib_dir)

      FileUtils.cp(File.join(c[:build_dir], "lib", "cppunit#{libTrailer}.lib"),
                   File.join(lib_dir, "cppunit.lib"),
                   :verbose => $verbose)

      # install headers
      puts "installing headers..."
      hdr_dir = File.join(c[:output_dir], "include")
      FileUtils.mkdir_p(hdr_dir)

      FileUtils.rm_rf(hdr_dir, "cppunit")
      FileUtils.cp_r(File.join(c[:src_dir], "include", "cppunit"),
                     hdr_dir, :verbose => $verbose)
    }
  }
}
