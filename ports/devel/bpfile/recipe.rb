{
  :url => 'http://cloud.github.com/downloads/browserplus/bp-file/bpfile-0.0.1.tgz',
  :md5 => '992845fa8e80f2c7ca3405d0c4af474a',
  :configure => lambda { |c|
    btstr = c[:build_type].to_s.capitalize
    cmakeGen = nil
    # on windows we must specify a generator, we'll get that from the
    # passed in configuration
    cmakeGen = "-G \"#{c[:cmake_generator]}\"" if c[:cmake_generator]
    cmLine = "cmake -DCMAKE_BUILD_TYPE=\"#{btstr}\" #{cmakeGen} " +
             " -DBUILD_DIR=\"#{c[:output_dir]}\""  +
             " \"#{c[:src_dir]}\"" 
    puts cmLine
    system(cmLine)
  },
  :build => {
    :Windows => lambda { |c|
      buildStr = c[:build_type].to_s.capitalize
      system("devenv bp-file.sln /Build #{buildStr}")
    },
    [ :MacOSX, :Linux ] => "make" 
  },
  :install => lambda { |c|
    # set up vars and dirs
    bt_str = c[:build_type].to_s

    # copy in header
    Dir.glob(File.join(c[:src_dir], "api", "bpfile","*.h")).each { |f|
      FileUtils.cp_r(f, c[:output_inc_dir])
    }

    # copy in lib
    lib = File.join(c[:build_dir], "src", "libbpfile_s.a")
    if c[:platform] == :Windows
      lib = File.join(c[:build_dir], "src", bt_str, "bpfile_s.lib")
    end
    FileUtils.cp(lib, c[:output_lib_dir], :verbose => true)
  }
}
