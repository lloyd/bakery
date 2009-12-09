# zip depends on zlib, which must be built first
#
{
  :url => 'http://www.winimage.com/zLibDll/unzip101e.zip',
  :md5 => '59e14911bffbb40ce49aa38f6f1efd2a',
  :build => {
    :Windows => lambda { |c|
      zlibIncDir = File.join(c[:output_inc_dir], "..", "zlib")
      if (!File.directory?(zlibIncDir))
        raise "zlib must be built before zip"
      end
      Dir.chdir(c[:src_dir]) do
        cflags = "/Zi /EHsc /W4 /wd4131 /wd4244 /wd4189 /wd4245 /wd4100"
        cflags += " /wd4996 -I#{zlibIncDir} -I../.."
        cflags += " -DWINDOWS -D_WINDOWS -DWIN32 -D_WIN32 -DXP_WIN32"
        if c[:build_type] == :debug
          cflags += " /MTd -DDEBUG -D_DEBUG"
        else
          cflags += " /MT /O2"
        end
        ENV["CFLAGS"] = ENV['CFLAGS'].to_s + cflags
        system("nmake -e -f Makefile")
        Dir.glob("*.obj").each do |o|
          FileUtils.cp(o, c[:build_dir])
        end
        FileUtils.cp("zip_s.lib", c[:build_dir])
      end
    },
    [:Linux, :MacOSX] => lambda { |c|
      zlibIncDir = File.join(c[:output_inc_dir], "..", "zlib")
      if (!File.directory?(zlibIncDir))
        raise "zlib must be built before zip"
      end
      Dir.chdir(c[:src_dir]) do
        cflags = "-I#{zlibIncDir} -I../.."
        if c[:platform] == :MacOSX
          cflags += c[:os_compile_flags]
          ENV['LDFLAGS'] = ENV['LDFLAGS'].to_s + c[:os_link_flags]
        end
        if c[:build_type] == :debug
          cflags += " -g -O0"
        end
        ENV["CFLAGS"] = ENV['CFLAGS'].to_s + cflags
        puts "ruby CFLAGS = #{ENV['CFLAGS'].to_s}"
        puts "ruby LDFLAGS = #{ENV['LDFLAGS'].to_s}"
        system("make -e")
        Dir.glob("*.o").each do |o|
          FileUtils.cp(o, c[:build_dir])
        end
        FileUtils.cp("libzip_s.a", c[:build_dir])
      end
    }
  },
  :install => {
    :Windows => lambda { |c|
      puts "Installing libs..."
      src = File.join(c[:src_dir], "zip_s.lib")
      dst = File.join(c[:output_lib_dir], "zip_s.lib")
      puts "copying from #{src} to #{dst}"
      FileUtils.cp(src, dst, :verbose => true)

      puts "Installing headers..."
      Dir.glob(File.join(c[:src_dir], "*.h")).each do |h| 
        FileUtils.cp(h, c[:output_inc_dir], :verbose => true)
      end
    },
    [:Linux, :MacOSX] => lambda { |c|
      puts "Installing libs..."
      src = File.join(c[:src_dir], "libzip_s.a")
      dst = File.join(c[:output_lib_dir], "libzip_s.a")
      puts "copying from #{src} to #{dst}"
      FileUtils.cp(src, dst, :verbose => true)

      puts "Installing headers..."
      Dir.glob(File.join(c[:src_dir], "*.h")).each do |h| 
        FileUtils.cp(h, c[:output_inc_dir], :verbose => true)
      end
    }      
  }
}

