
{
  :url => "http://prdownloads.sourceforge.net/cppunit/cppunit-1.12.1.tar.gz",
  :md5 => "bd30e9cf5523cdfc019b94f5e1d7fd19",
  :configure => {
    [ :Linux, :MacOSX ] => lambda { |c|
      puts "Configuring #{c[:build_type].to_s} bits..."
      ldflags = ""
      cxxflags = c[:build_type] == :debug ? "-g -O0" : ""
      if c[:platform] == :MacOSX
        cxxflags += c[:os_compile_flags]
      end
      cfgScript = File.join(c[:src_dir], "configure")
      configCmd = "#{cfgScript} --enable-static --disable-shared"
      configCmd += " --prefix=#{c[:build_dir]} --disable-doxygen"
      configCmd += " CXXFLAGS=\"#{cxxflags}\""
      if c[:platform] == :MacOSX
        configCmd += " LDFLAGS=\"#{c[:os_link_flags]}\""
      end
      # the '|| echo' prevents termination since configCmd fails.  nice
      system("#{configCmd} || echo")
    }
  },

  :build => {
    [ :Linux, :MacOSX ] => lambda { |c|
      system("make")
      system("make install")
    },
    :Windows => lambda { |c|
      buildType = c[:build_type].to_s
      system("devenv CppUnitLibraries.sln /build \"#{buildType} static\"")
    }
  },

  :install => {
    [ :Linux, :MacOSX ] => lambda { |c|
      Dir.glob(File.join(c[:build_dir], "lib", "*cppunit*")).each { |f|
        FileUtils.cp(f, c[:output_lib_dir], :verbose => true)
      }
    },

    :Windows => lambda { |c|
      # install static lib
      puts "installing #{c[:build_type].to_s} static library..."
      libTrailer = (c[:build_type] == :debug) ? "d" : ""
      FileUtils.cp(File.join(c[:build_dir], "lib", "cppunit#{libTrailer}.lib"),
                   File.join(c[:output_lib_dir], "cppunit.lib"),
                   :verbose => true)
    }
  },

  :post_install_common => lambda { |c|
    # install headers
    puts "installing headers..."
    Dir.glob(File.join(File.join(c[:src_dir], "include",
                                 "cppunit", "*"))).each { |h| 
      FileUtils.cp_r(h, c[:output_inc_dir], :verbose => true)
    }
  }
}

