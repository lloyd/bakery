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
    },
    :Windows => lambda { |c| 
      if c[:build_type] == :debug
        # patched jpegsrc includes a substitution target in libpng.vcproj
        # we'll sub that now with the path to zlib headers
        
        vcpPath = File.join(c[:src_dir], "projects",
                            "visualc71", "libpng.vcproj")

        raise "can't find libpng.vcproj (#{vcpPath})" if !File.readable?(vcpPath)

        # read the whole thing
        contents = File.read(vcpPath)

        # sub in the proper path
        libDir = File.join(File.dirname(File.join(c[:output_inc_dir])), "zlib")
        realPath = File.expand_path(libDir).gsub(/\//,"\\")
        puts "replacing ZLIB_INCLUDE_PATH with '#{realPath}'"
        contents.gsub!(/ZLIB_INCLUDE_PATH/, realPath)
        
        # write the whole thing
        File.open(vcpPath, "w") { |f| f.write contents }
      end
    }
  },
  :build => {
    [ :Linux, :MacOSX ] => "make",
    :Windows => lambda { |c|
      Dir.chdir(File.join(c[:src_dir], "projects", "visualc71")) do
        bt = c[:build_type].to_s.capitalize
        system("devenv libpng.sln /build \"LIB #{bt}\" /project libpng")
      end
    }
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
        tgt = File.join(c[:output_lib_dir],
                        File.basename(l).sub(/\.a$/, "_s.a"))
        FileUtils.mv(l, tgt, :verbose => true)
      }
    },
    :Windows => lambda { |c|
      puts "installing lib"
      bt = c[:build_type].to_s.capitalize
      suffix = bt == "Debug" ? "d" : ""
      FileUtils.install(File.join(c[:src_dir], 
                                  "projects",
                                  "visualc71",
                                  "Win32_LIB_#{bt}",
                                  "libpng#{suffix}.lib"),
                        File.join(c[:output_lib_dir], "libpng_s.lib"),
                        :verbose => true)

      puts "installing headers"
      ["png.h", "pngconf.h"].each do |f|
        FileUtils.install(File.join(c[:src_dir], f), c[:output_inc_dir],
                          :verbose => true)
      end
    }
  }
}
