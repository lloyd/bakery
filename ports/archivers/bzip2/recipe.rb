{
  :url => 'http://www.bzip.org/1.0.5/bzip2-1.0.5.tar.gz',
  :md5 => '3c15a0c8d1d3ee1c46a1634d00617b1a',
  :build => {
    :Windows => lambda { |c|
      Dir.chdir(c[:src_dir]) do
        cflags = "/Zi /EHsc /W4 -DWIN32 -D_FILE_OFFSET_BITS=64 -nologo"
        if c[:build_type] == :debug
          cflags += " /MTd -DDEBUG -D_DEBUG"
        else
          cflags += " /MT /O2 -DNDEBUG -D_NDEBUG"
        end
        ENV["CFLAGS"] = cflags
        system("nmake -e -f makefile.msc clean all")
      end
    },
    [:Linux, :MacOSX] => lambda { |c|
      Dir.chdir(c[:src_dir]) do
        cflags = "-Wall -Winline -D_FILE_OFFSET_BITS=64 "
        if c[:platform] == :MacOSX
          cflags += c[:os_compile_flags]
          ENV['LDFLAGS'] = ENV['LDFLAGS'].to_s + c[:os_link_flags]
        end
        if c[:build_type] == :debug
          cflags += " -g -O0"
        else
          cflags += " -O2"
        end
        ENV["CFLAGS"] = ENV['CFLAGS'].to_s + cflags
        system("make -e clean all")
      end
    }
  },
  :install => { 
    :Windows => lambda { |c|
      puts "Installing libs..."
      src = File.join(c[:src_dir], "libbz2.lib")
      dst = File.join(c[:output_lib_dir], "bz2_s.lib")
      puts "copying from #{src} to #{dst}"
      FileUtils.cp(src, dst, :verbose => true)

      puts "Installing headers..."
      Dir.glob(File.join(c[:src_dir], "*.h")).each do |h| 
        FileUtils.cp(h, c[:output_inc_dir], :verbose => true)
      end
    },
    [:Linux, :MacOSX] => lambda { |c|
      puts "Installing libs..."
      src = File.join(c[:src_dir], "libbz2.a")
      dst = File.join(c[:output_lib_dir], "libbz2_s.a")
      puts "copying from #{src} to #{dst}"
      FileUtils.cp(src, dst, :verbose => true)

      puts "Installing headers..."
      Dir.glob(File.join(c[:src_dir], "*.h")).each do |h| 
        FileUtils.cp(h, c[:output_inc_dir], :verbose => true)
      end
    }      
  }
}

