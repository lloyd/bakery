{
  :url => 'http://cloud.github.com/downloads/lloyd/yajl/yajl-1.0.7.tar.gz',
  :md5 => 'a4436163408fe9b8c9545ca028ef1b4f',
  :configure => lambda { |c|
    btstr = c[:build_type].to_s.capitalize
    cmakeGen = nil
    # on windows we must specify a generator, we'll get that from the
    # passed in configuration
    cmakeGen = "-G \"#{c[:cmake_generator]}\"" if c[:cmake_generator]
    cmLine = "cmake -DCMAKE_BUILD_TYPE=\"#{btstr}\" " +
                   "-DCMAKE_INSTALL_PREFIX=\"#{c[:output_dir]}\" " +
                   "#{cmakeGen} " +
                   " \"#{c[:src_dir]}\"" 
    system(cmLine)
  },
  :build => {
    :Windows => lambda { |c|
      buildStr = c[:build_type].to_s.capitalize
      system("devenv YetAnotherJSONParser.sln /Build #{buildStr}")
    },
    [ :MacOSX, :Linux ] => "make" 
  },
  :install => {
    :Windows => lambda { |c|
      Dir.glob(File.join(c[:build_dir], "yajl-1.0.7", "*")).each { |d|
        FileUtils.cp_r(d , c[:output_dir])
      }
    },
    [ :Linux, :MacOSX ] => "make install"
  },
  :post_install => {
    [ :Linux, :MacOSX ] => lambda { |c|
      system("make install")

      # now let's move output to the appropriate place
      # i.e. move from lib/libfoo.a to lib/debug/foo.a
      Dir.glob(File.join(c[:output_dir], "lib", "*")).each { |f|
        FileUtils.mv(f, c[:output_lib_dir]) if !File.directory? f
      }
    }
  }
}
