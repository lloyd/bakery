{
  :url => 'http://cloud.github.com/downloads/lloyd/yajl/yajl-1.0.4.tar.gz',
  :md5 => '3d7897500f1acaa78d3d2e2f9cafd5f1',
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
    puts cmLine
    system(cmLine)
  },
  :build => {
    :Windows => lambda { |c|
      buildStr = c[:build_type].to_s.capitalize
      system("devenv YetAnotherJSONParser.sln /Build #{buildStr}")
    },
    :MacOSX => "make", 
    :Linux => "make"
  },
  :install => lambda { |c|
    if c[:platform] != :Windows
      system("make install")
      # now let's move output to the appropriate place
      # i.e. move from lib/libfoo.a to lib/debug/foo.a
      libdir = File.join(c[:output_dir], "lib", c[:build_type].to_s)
      FileUtils.mkdir_p(libdir)
      Dir.glob(File.join(c[:output_dir], "lib", "*")).each { |f|
        FileUtils.mv(f, libdir) if !File.directory? f
      }
    else
      Dir.glob(File.join(c[:build_dir], "yajl-1.0.4", "*")).each { |d|
        FileUtils.cp_r(d , c[:output_dir])
      }
    end
  }
}
