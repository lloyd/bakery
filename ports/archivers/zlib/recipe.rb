{
  :url => "http://www.zlib.net/zlib-1.2.3.tar.gz",
  :md5 => "debc62758716a169df9f62e6ab2bc634",
  :configure => {
    [ :Linux, :MacOSX ] => lambda { |c|
      # zlib doesn't like out of source builds
      Dir.chdir(c[:src_dir]) {
        ENV['CFLAGS'] = "-g -O0 #{ENV['CFLAGS']}" if (c[:build_type] == :debug)
        system("./configure")
      }
    }
  },
  :build => {
    [ :Linux, :MacOSX ] => lambda { |c|
      # zlib doesn't like out of source builds
      Dir.chdir(c[:src_dir]) {
        system("make")
      }
    }
  },
  :install => {
    [ :Linux, :MacOSX ] => lambda { |c|
      puts "installing static library..."
      FileUtils.cp(File.join(c[:src_dir], "libz.a"),
                   File.join(c[:output_lib_dir], "libzlib_s.a"),
                   :verbose => true)

      puts "installing headers..."
      ["zconf.h", "zlib.h"].each { |h|
        FileUtils.cp(File.join(c[:src_dir], h),
                     c[:output_inc_dir], :verbose => true)
      }
    }
  }
}  
