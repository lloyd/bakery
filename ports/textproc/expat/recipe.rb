def setupEnv(c) 
  if c[:platform] != :Windows
    ENV['CFLAGS'] = ENV['CFLAGS'].to_s + c[:os_compile_flags]
    if c[:build_type] == :debug
      ENV['CFLAGS'] = ENV['CFLAGS'].to_s + " -g -O0"
    end
    ENV['LDFLAGS'] = ENV['LDFLAGS'].to_s + c[:os_link_flags]
  end
end

{
  :url => 'http://downloads.sourceforge.net/expat/expat-2.0.1.tar.gz',
  :md5 => 'ee8b492592568805593f81f8cdf2a04c',
  :configure => {
    [ :MacOSX, :Linux ] => lambda { |c|
      setupEnv(c)
      Dir.chdir(c[:src_dir]) do
        configCmd = "./configure --disable-shared --enable-static --prefix=#{c[:build_dir]}"
        system(configCmd)
      end
    }
  },
  :build => {
    :Windows => lambda { |c|
      Dir.chdir(c[:src_dir]) do
        buildStr = c[:build_type].to_s.capitalize
        devenvOut = File.join(c[:log_dir], "devenv_#{c[:build_type]}.txt")
        system("devenv expat.sln /Build #{buildStr} /project expat_static > #{devenvOut}")
      end
    },
    [ :MacOSX, :Linux ] => lambda { |c|
      setupEnv(c)
      Dir.chdir(c[:src_dir]) do
        system("make clean")
        system("make install")
      end
    }
  },
  :install => {
    :Windows => lambda { |c|
      buildStr = c[:build_type].to_s.capitalize
      FileUtils.cp(File.join(c[:src_dir], "win32", "bin",
                             buildStr, "libexpatMT.lib"),
                   File.join(c[:output_lib_dir], "libexpatMT.lib"),
                   :verbose => true)
    },
    [ :MacOSX, :Linux ] => lambda { |c|
      ["libexpat.a", "libexpat.la"].each do |l|
        FileUtils.cp(File.join(c[:build_dir], "lib", l),
                     File.join(c[:output_lib_dir], l),
                     :verbose => true)
      end
    },
  },
  :post_install_common => lambda { |c|
    ["expat.h", "expat_external.h"].each do |h|
      FileUtils.cp(File.join(c[:src_dir], "lib", h),
                   File.join(c[:output_inc_dir], h),
                   :verbose => true)
    end
  }
}
