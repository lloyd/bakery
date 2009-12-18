{
  :url => "http://ftp.ruby-lang.org/pub/ruby/ruby-1.9.1-p376.tar.bz2",
  :md5 => "e019ae9c643c5efe91be49e29781fb94",
  :configure => {
    [ :Linux, :MacOSX ] => lambda { |c|
      if $platform == :MacOSX
        ENV['CFLAGS'] = "#{c[:os_compile_flags]} #{ENV['CFLAGS']}"
        ENV['LDFLAGS'] = "#{c[:os_link_flags]} #{ENV['LDFLAGS']}"
      end
      if c[:build_type] == :debug
        ENV['CFLAGS'] = "-g -O0 #{ENV['CFLAGS']}"
      end

      configScript = File.join(c[:src_dir], "configure")
      configstr = "#{configScript} --enable-shared --prefix=#{c[:output_dir]} "
      configstr = configstr + "--disable-install-doc"
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
      
      # now move output in lib dir into build config dir
      Dir.glob(File.join(c[:output_dir], "lib", "*ruby*")).each { |l|
        tgtBasename = File.basename(l)
        tgt = File.join(c[:output_lib_dir], tgtBasename)
        FileUtils.mv(l, tgt, :verbose => true)
      }
    }
  },
  :post_install_common => {
    [ :Linux, :MacOSX ] => lambda { |c|
      rb19dir = File.join(c[:output_dir], "include", "ruby-1.9.1")
      Dir.glob(File.join(rb19dir, "*")).each { |h|
        FileUtils.mv(h, c[:output_inc_dir], :verbose => true)
      }
      FileUtils.rmdir(rb19dir)
    }
  }
}
