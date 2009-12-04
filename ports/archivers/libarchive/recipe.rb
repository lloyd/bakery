{
  :url => 'http://libarchive.googlecode.com/files/libarchive-2.6.2.tar.gz',
  :md5 => 'e31fcacd3f2b996988c0852a5edfc680',
  :configure => {
    [:Linux, :MacOSX] => lambda { |c|
      if c[:platform] == :Darwin
        ENV['CFLAGS'] = ENV['CFLAGS'].to_s + c[:darwinCompatCompileFlags]
        ENV['CXXFLAGS'] = ENV['CXXFLAGS'].to_s + c[:darwinCompatCompileFlags]
      end

      if c[:build_type] == :debug
        ENV['CFLAGS'] = ENV['CFLAGS'].to_s + " -g -O0"
      end

      stageDir = File.join(File.dirname(c[:build_dir]), "stage")
      configCmd = File.join(c[:src_dir], "configure")    
      configCmd += " --without-lzmadec --without-bz2lib"
      configCmd += " --without-zlib --disable-shared --disable-bsdcpio"
      configCmd += " --disable-bsdtar --enable-static --prefix=#{stageDir}"
      system(configCmd)
      puts "config cmd: #{configCmd}"
    }
  },
  :build => {
    :Windows => lambda { |c|
      buildStr = c[:build_type].to_s.capitalize
      pathToSoln = File.join(c[:src_dir], "windows", "vc90", "libarchive.sln")
      pathToSoln.gsub!(/\//, "\\")
      buildCmd = "devenv \"#{pathToSoln}\" /Build #{buildStr}"
      puts buildCmd
      system(buildCmd)
    },
    :MacOSX => "make", 
    :Linux => "make"
  },
  :install => {
    :Windows => lambda { |c|
      puts "Installing libs..."
      debug_str = (c[:build_type] == :debug) ? "-d" : ""
      src = File.join(c[:src_dir], "lib", "libarchive-vc90-mt#{debug_str}.lib")
      dst = File.join(c[:output_lib_dir], "archive_s.lib")
      puts "copying from #{src} to #{dst}"
      FileUtils.cp(src, dst, :verbose => true)

      puts "Installing headers..."
      [ "archive.h", "archive_entry.h" ].each do |h|
        FileUtils.cp(File.join(c[:src_dir], "libarchive", h),
                     c[:output_inc_dir], :verbose => true)
      end
    },
    [:Linux, :MacOSX] => lambda { |c|
      stageDir = File.join(File.dirname(c[:build_dir]), "stage")
      system("make install")

      puts "Installing headers..."
      [ "archive.h", "archive_entry.h" ].each do |h|
        FileUtils.cp(File.join(stageDir, "include", h),
                     c[:output_inc_dir], :verbose => true)
      end

      puts "Installing static library..."
      FileUtils.cp(File.join(stageDir, "lib", "libarchive.a"),
                   File.join(c[:output_lib_dir], "libarchive_s.a"),
                   :verbose => true)
    }      
  }
}

