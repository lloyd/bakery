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
    [:Linux, :MacOSX] => lambda { |c|
      configCmd = File.join(c[:src_dir], "source", "runConfigureICU")    
      configCmd += " #{c[:platform].to_s} --prefix=#{c[:output_dir]} "
      configCmd += " --enable-static --disable-shared --disable-icuio --disable-layout"
      if c[:build_type] == :debug
        configCmd += " --enable-debug --disable-release"
        ENV['CFLAGS'] = "#{ENV['CFLAGS']} -g -O0"
      end
      if $platform == :MacOSX
        ENV['CFLAGS'] = "#{c[:os_compile_flags]} #{ENV['CFLAGS']}"
        ENV['LDFLAGS'] = "#{c[:os_link_flags]} #{ENV['LDFLAGS']}"
      end
      puts "config cmd: #{configCmd}"
      system(configCmd)
    }
  },
  :build => {
    :Windows => lambda { |c| },
    [ :MacOSX, :Linux ] => "make"
  },
  :install => {
    :Windows => lambda { |c| },
    [ :Linux, :MacOSX ] => lambda { |c|
      system("make install")
      # install static libs
      Dir.glob(File.join(c[:output_dir], "lib", "*.a")).each { |l|
        FileUtils.mv(l, c[:output_lib_dir], :verbose => true)
      }
    }
  },
  :post_install_common => {
    [ :Linux, :MacOSX ] => lambda { |c|
      FileUtils.mv(File.join(c[:output_dir], "include", "unicode"),
                   c[:output_inc_dir], :verbose => true)
    }      
  }
}

