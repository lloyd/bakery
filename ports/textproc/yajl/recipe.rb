{
  :url => 'http://cloud.github.com/downloads/lloyd/yajl/yajl-1.0.4.tar.gz',
  :md5 => '3d7897500f1acaa78d3d2e2f9cafd5f1',
  :configure => lambda { |c|
    # XXX: on windows we must specify a generator!
    btstr = c[:build_type].capitalize
    cmLine = "cmake -DCMAKE_BUILD_TYPE=\"#{btstr}\" " +
                   "-DCMAKE_INSTALL_PREFIX=\"#{c[:output_dir]}\" " +
                   " \"#{c[:src_dir]}\"" 
    system(cmLine)
  },
  :build => {
    :Windows => lambda { |buildType|
      puts "now building --> #{buildType}"
    },
    :MacOSX => "make", 
    :Linux => "make"
  },
  :install => lambda { |c|
    system("make install")
    if c[:platform] != :Windows
      # now let's move output to the appropriate place
      # i.e. move from lib/libfoo.a to lib/debug/foo.a
      libdir = File.join(c[:output_dir], "lib", c[:build_type].to_s)
      FileUtils.mkdir_p(libdir)
      Dir.glob(File.join(c[:output_dir], "lib", "*")).each { |f|
        FileUtils.mv(f, libdir) if !File.directory? f
      }
    end
  }
}
