{
  :url => 'http://downloads.sourceforge.net/project/libpng/00-libpng-stable/1.2.40/libpng-1.2.40.tar.bz2',
  :md5 => '29bbd1c3cbe54b04bfc2bda43067ccb5',
  :configure => {
    [ :Linux, :MacOSX ] => lambda { |c|
      ENV['CFLAGS'] = "#{c[:os_compile_flags]} #{ENV['CFLAGS']}"
      ENV['CFLAGS'] += ' -g -O0 ' if c[:build_type] == :debug
      ENV['LDFLAGS'] = "#{c[:os_link_flags]} #{ENV['LDFLAGS']}"
      cfgScript = File.join(c[:src_dir], "configure")
      cfgOpts = "--enable-static --disable-shared --prefix=\"#{c[:output_dir]}\""
      puts "#{cfgScript} #{cfgOpts}"
      system("#{cfgScript} #{cfgOpts}")
    }    
  },
  :build => {
    [ :Linux, :MacOSX ] => "make"
  },
  :install => {
    [ :Linux, :MacOSX ] => lambda { |c|
      system("make install")

      # move headers into place (only once)
      if c[:build_type] == :release
        Dir.glob(File.join(c[:output_dir], "include", "png*h")).each { |h|
          FileUtils.mv(h, c[:output_inc_dir], :verbose => true)
        }
        FileUtils.mv(File.join(c[:output_dir], "include", "libpng12"),
                     c[:output_inc_dir],
                     :verbose => true)      
      end

      # move library into place
      Dir.glob(File.join(c[:output_dir], "lib", "libpng*a")).each { |l|
        FileUtils.mv(l, c[:output_lib_dir], :verbose => true)
      }
    }
  }
}
