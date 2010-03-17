{
  :url => "http://www.zlib.net/zlib-1.2.4.tar.gz",
  :md5 => "47f6ed51b3c83a8534f9228531effa18",
  :configure => {
    [ :Linux, :MacOSX ] => lambda { |c|
      ENV['CFLAGS'] = "#{c[:os_compile_flags]} #{ENV['CFLAGS']}"
      ENV['CFLAGS'] += ' -g -O0 ' if c[:build_type] == :debug
      ENV['LDFLAGS'] = "#{c[:os_link_flags]} #{ENV['LDFLAGS']}"

      # zlib doesn't like out of source builds
      Dir.chdir(c[:src_dir]) {
        system("./configure")
      }
    },
    :Windows => "echo no configuration required"
  },
  :build => {
    [ :Linux, :MacOSX ] => lambda { |c|
      # zlib doesn't like out of source builds
      Dir.chdir(c[:src_dir]) {
        system("make")
      }
    },
    :Windows => lambda { |c|
      pathToSLN = File.join(c[:src_dir], "projects", "visualc6", "zlib.sln")
      bt = c[:build_type].to_s.capitalize
      devenvCmd = "devenv #{pathToSLN} /build \"LIB #{bt}\" /project zlib"
      puts "issuing: #{devenvCmd}"
      system(devenvCmd)
    }
  },
  :install => {
    [ :Linux, :MacOSX ] => lambda { |c|
      puts "installing static library..."
      FileUtils.cp(File.join(c[:src_dir], "libz.a"),
                   File.join(c[:output_lib_dir], "libzlib_s.a"),
                   :verbose => true)
    },
    :Windows => lambda { |c|
      bt = c[:build_type].to_s.capitalize      
      suffix = (bt == "Debug") ? "d" : ""
      FileUtils.install(File.join(c[:src_dir], "projects", "visualc6",
                                  "Win32_LIB_#{bt}", "zlib#{suffix}.lib"),
                        File.join(c[:output_lib_dir], "zlib_s.lib"),
                        :verbose => true)
    }
  },
  :post_install => lambda { |c|
    if c[:build_type] == :release
      puts "installing headers..."
      ["zconf.h", "zlib.h"].each { |h|
        FileUtils.cp(File.join(c[:src_dir], h),
                     c[:output_inc_dir], :verbose => true)
      }
    end
  }
}
