{
  :url => 'http://softlayer.dl.sourceforge.net/project/graphicsmagick/graphicsmagick/1.3.7/GraphicsMagick-1.3.7.tar.bz2',
  :md5 => '42bfd382ddcda399880721170bcbf61b',
  :configure => {
    [ :Linux, :MacOSX ] => lambda { |c|
      jpg_hdrs = File.join(c[:output_dir], "include", "jpeg")
      png_hdrs = File.join(c[:output_dir], "include", "libpng")
      lib_dir = File.join(c[:output_dir], "lib")
      bt = c[:build_type].to_s
      ENV['CFLAGS'] = "-I#{jpg_hdrs}/jpeg -I#{png_hdrs}/libpng #{ENV['CFLAGS']}" 
      ENV['CFLAGS'] += " #{c[:os_compile_flags]}"
      if c[:build_type] == :debug
        ENV['CFLAGS'] += " -g -O0"
      end
      ENV['LDFLAGS'] = " -L#{lib_dir}/#{bt} #{c[:os_link_flags]} #{ENV['LDFLAGS']}"
      cfgOpts = "--enable-static --disable-shared --without-bzlib " +
                "--without-dps --without-jp2 --without-lcms --without-tiff " +
                "--without-trio --without-ttf --without-xml --without-x " +
                "--disable-openmp --prefix=#{c[:output_dir]}" 
      cfgScript = File.join(c[:src_dir], "configure")
      puts("LDFLAGS=\"#{ENV['LDFLAGS']}\" #{cfgScript} #{cfgOpts}")      
      system("LDFLAGS=\"#{ENV['LDFLAGS']}\" #{cfgScript} #{cfgOpts}")
    }
  },
  :build => {
    [ :Linux, :MacOSX ] => "make"
  },
  :install => {
    [ :Linux, :MacOSX ] => lambda { |c|
      system("make install")

      # rename static lib (append _s and move to buildtype dir)
      lib_dir = File.join(c[:output_dir], "lib", c[:build_type].to_s)
      puts "creating '#{lib_dir}'"
      FileUtils.mkdir_p(lib_dir)
      Dir.glob(File.join(c[:output_dir], "lib", "libGraphics*")).each { |l|
        newFname = File.basename(l).sub(/\.a$/, "_s.a")
        FileUtils.mv(l, File.join(lib_dir, newFname), :verbose => true)
      }
    }
  }
}
