{
  :url => "http://quirkysoft.googlecode.com/files/jpegsrc.v6b.tar.gz",
  :md5 => "dbd5f3b47ed13132f04c685d608a7547",
  :configure => {
    [ :Linux, :MacOSX ] => lambda { |c|
      ENV['CFLAGS'] = "#{c[:os_compile_flags]} #{ENV['CFLAGS']}"
      ENV['CFLAGS'] += ' -g -O0 ' if c[:build_type] == :debug
      ENV['LDFLAGS'] = "#{c[:os_link_flags]} #{ENV['LDFLAGS']}"
      cfgScript = File.join(c[:src_dir], "configure")
      cfgOpts = "--prefix=\"#{c[:output_dir]}\""
      puts "#{cfgScript} #{cfgOpts}"
      system("#{cfgScript} #{cfgOpts}")
    }    
  },
  :build => {
    [ :Linux, :MacOSX ] => "make libjpeg.a"
  },
  :install => {
    [ :Linux, :MacOSX ] => lambda { |c|
      system("make install-lib")

      # move headers into place
      Dir.glob(File.join(c[:output_dir], "include", "j*h")).each { |h|
        FileUtils.mv(h, c[:output_inc_dir])
      }

      # move library into place
      FileUtils.mv(File.join(c[:output_dir], "lib", "libjpeg.a"),
                   File.join(c[:output_lib_dir], "libjpeg_s.a"),
                   :verbose => true)
    }
  }
}
