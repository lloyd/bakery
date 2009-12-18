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
    }
  }
}
