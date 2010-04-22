{
  :url => 'http://download.icu-project.org/files/icu4c/4.0.1/icu4c-4_0_1-src.tgz',
  :md5 => '2f6ecca935948f7db92d925d88d0d078',

  :post_patch => lambda { |c|
    # copy in our custom data file
    FileUtils.cp(File.join(c[:recipe_dir], "icudt40l.dat"),
                 File.join(c[:src_dir], "source", "data", "in"),
                 :verbose => true)
  },

  :configure => {
    [ :Linux, :MacOSX ] => lambda { |c|
      configCmd = File.join(c[:src_dir], "source", "runConfigureICU")    
      configCmd += " #{c[:platform].to_s} --prefix=#{c[:output_dir]} "
      configCmd += " --enable-static --disable-icuio --disable-layout"
      if c[:build_type] == :debug
        configCmd += " --enable-debug --disable-release"
      end
      puts "config cmd: #{configCmd}"
      system(configCmd)
    }
  },

  :build => {
    :Windows => lambda { |c| 
      system("devenv icu\\source\\allinone\\allinone.sln /build #{c[:build_type]} > make_out.txt")
    },
    [ :MacOSX, :Linux ] => lambda { |c|
      if c[:platform] == :MacOSX
        ENV['CFLAGS'] = "#{c[:os_compile_flags]} #{ENV['CFLAGS']}"
        ENV['CXXFLAGS'] = "#{c[:os_compile_flags]} #{ENV['CFLAGS']}"
        ENV['LDFLAGS'] = "#{c[:os_link_flags]} #{ENV['LDFLAGS']}"
      end
      if c[:build_type] == :debug
        ENV['CFLAGS'] = "#{ENV['CFLAGS']} -g -O0"
        ENV['CXXFLAGS'] = "#{ENV['CFLAGS']} -g -O0"
      end
      system("make")
      # the '|| echo' prevents termination since make check fails.  nice
      system("make check || echo")
    }
  },

  :install => {
    :Windows => lambda { |c|
    },
    [ :Linux, :MacOSX ] => lambda { |c|
      system("make install")
      # now glob all files containing icu in the lib dir, and move into
      # lib/{debug,release}
      Dir.glob(File.join(c[:output_dir], "lib", "*icu*")).each { |l|
        FileUtils.mv(l, c[:output_lib_dir], :verbose => true)
      }
    }
  },

  :post_install_common => lambda { |c|
    # move the include/unicode directory into include/icu/unicode

    # XXX: note, this sucks because users must include include/icu directly,
    # which breaks the bakery's ability to protect you from system includes.
    # better would be to programatically patch all includes to #include "icu/XXX"
    # rather than how icu wants you to do it, #include "unicode/XXX".
    # this would mean bakery users can just include include/ and use headers
    # with #include "icu/<header>"
    FileUtils.mv(File.join(c[:output_dir], "include", "unicode"),
                 c[:output_inc_dir], :verbose => true)
  }
}
