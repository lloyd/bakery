{
  :url => 'http://libarchive.googlecode.com/files/libarchive-2.7.1.tar.gz',
  :md5 => 'f43382413b4457d0e192771b100a66e7',
  :configure => lambda { |c|
    if c[:platform] == :Darwin
      ENV['CFLAGS'] = ENV['CFLAGS'].to_s + c[:darwinCompatCompileFlags]
      ENV['CXXFLAGS'] = ENV['CXXFLAGS'].to_s + c[:darwinCompatCompileFlags]
    end

    if c[:build_type] == :debug
      ENV['CFLAGS'] = ENV['CFLAGS'].to_s + " -g -O0"
    end

    configCmd = "./configure --without-lzmadec --without-bz2lib"
    configCmd += " --without-zlib --disable-shared --disable-bsdcpio"
    configCmd += " --disable-bsdtar --enable-static --prefix=#{c[:output_dir]}"
    system(configCmd)
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
    if c[:platform] == :Windows
      system("make install")
      # now let's move output to the appropriate place
      # i.e. move from lib/libfoo.a to lib/debug/foo.a
      libdir = File.join(c[:output_dir], "lib", c[:build_type].to_s)
      FileUtils.mkdir_p(libdir)
      Dir.glob(File.join(c[:output_dir], "lib", "*")).each { |f|
        FileUtils.mv(f, libdir) if !File.directory? f
      }
    else
      system("make install")
    end
  }
}
