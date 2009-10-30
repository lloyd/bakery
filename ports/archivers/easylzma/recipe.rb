{
  :url => 'http://cloud.github.com/downloads/lloyd/easylzma/easylzma-0.0.7.tar.gz',
  :md5 => '78b4d067c58208748f07c4b142db9bb2',
  :configure => lambda { |c|
    btstr = c[:build_type].to_s.capitalize
    cmakeGen = nil
    # on windows we must specify a generator, we'll get that from the
    # passed in configuration
    cmakeGen = "-G \"#{c[:cmake_generator]}\"" if c[:cmake_generator]
    cmLine = "cmake -DCMAKE_BUILD_TYPE=\"#{btstr}\" #{cmakeGen} " +
             " \"#{c[:src_dir]}\"" 
    system(cmLine)
  },
  :build => {
    :Windows => lambda { |c|
      buildStr = c[:build_type].to_s.capitalize
      system("devenv easylzma.sln /Build #{buildStr}")
    },
    [ :MacOSX, :Linux ] => "make" 
  },
  :install => lambda { |c|
    # set up vars and dirs
    pkg = "easylzma-0.0.7"
    bt_str = c[:build_type].to_s
    hdr_dir = File.join(c[:output_dir], "include", "easylzma")
    lib_dir = File.join(c[:output_dir], "lib", bt_str)
    bin_dir = File.join(c[:output_dir], "bin")
    FileUtils.mkdir_p(hdr_dir)
    FileUtils.mkdir_p(lib_dir)
    FileUtils.mkdir_p(bin_dir)

    # copy in headers
    Dir.glob(File.join(c[:build_dir], pkg, "include", "easylzma","*.h")).each { |f|
      FileUtils.cp_r(f, hdr_dir)
    }

    # copy in lib
    lib = File.join(c[:build_dir], pkg, "lib", "libeasylzma_s.a")
    if c[:platform] == :Windows
      lib = File.join(c[:build_dir], pkg, "lib", bt_str, "easylzma_s.lib")
    end
    FileUtils.cp(lib, lib_dir, { :verbose => true, :preserve=>true })

    # copy in bins (why not?)
    Dir.glob(File.join(c[:build_dir], pkg, "bin", "*")) do |b|
      FileUtils.cp(b, bin_dir, { :verbose => true, :preserve=>true })
    end
  }
}
