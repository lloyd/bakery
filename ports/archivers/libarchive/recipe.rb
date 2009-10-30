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

      configCmd = File.join(c[:src_dir], "configure")    
      configCmd += " --without-lzmadec --without-bz2lib"
      configCmd += " --without-zlib --disable-shared --disable-bsdcpio"
      configCmd += " --disable-bsdtar --enable-static --prefix=#{c[:output_dir]}"
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
      # set up directories
      hdr_dir = File.join(c[:output_dir], "include", "libarchive") 
      lib_dir = File.join(c[:output_dir], "lib", c[:build_type].to_s)
      FileUtils.mkdir_p(hdr_dir)
      FileUtils.mkdir_p(lib_dir)

      puts "Installing libs..."
      debug_str = (c[:build_type] == :debug) ? "-d" : ""
      src = File.join(c[:src_dir], "lib", "libarchive-vc90-mt#{debug_str}.lib")
      dst = File.join(lib_dir, "archive_s.lib")
      puts "copying from #{src} to #{dst}"
      FileUtils.cp(src, dst, :verbose => true)

      puts "Installing headers..."
      [ "archive.h", "archive_entry.h" ].each do |h|
        FileUtils.cp(File.join(c[:src_dir], "libarchive", h), hdr_dir,
                     :verbose => true)
      end
    },
    [:Linux, :MacOSX] => "make install"
  }
}

