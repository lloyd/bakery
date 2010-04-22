{
  :url => "http://openssl.org/source/openssl-0.9.8k.tar.gz",
  :md5 => "e555c6d58d276aec7fdc53363e338ab3",

  :configure => lambda { |c|
    Dir.chdir(c[:src_dir]) {
      if c[:platform] == :Windows
        configureCmd = "perl Configure VC-WIN32"
      else
        configureCmd = "sh ./config"
      end
      system("#{configureCmd} no-shared --prefix=#{c[:build_dir]}")
    }
  },

  :build => lambda { |c|
    Dir.chdir(c[:src_dir]) {
      # setup compile/link flags
      if c[:platform] != :Windows
        ENV['CFLAGS'] = ENV['CFLAGS'].to_s + c[:os_compile_flags]
        if c[:build_type] == :debug
          ENV['CFLAGS'] = ENV['CFLAGS'].to_s + " -g -O0"
        end
        ENV['LDFLAGS'] = ENV['LDFLAGS'].to_s + c[:os_link_flags]
      end

      if c[:platform] == :Darwin
        includeDir = File.join(c[:src_dir], "include")
        libDir = c[:src_dir]
        ENV['BP_EXTRA_CFLAGS'] = "-I#{includeDir} -L#{libDir}"
      end

      makeCmd = c[:platform] == :Windows ? "nmake -f ms\\nt.mak" : "make"

      system("ms\\do_masm.bat") if $platform == "Windows"
      system("#{makeCmd}")
      system("#{makeCmd} test")
      system("#{makeCmd} install")
    }
  },

  :install => lambda { |c|
    Dir.chdir(c[:build_dir]) {
      # install static libs
      puts "Installing libs..."
      if c[:platform] == :Windows
        ["ssleay32", "libeay32"].each() do |l|
          src = File.join("lib", "#{l}.lib")
          dst = File.join(c[:output_lib_dir], "#{l}_s.lib")
          puts "copying from #{src} to #{dst}"
          FileUtils.cp(src, dst, :verbose => true)
        end
      else
        ["libssl", "libcrypto"].each() do |l|
          src = File.join("lib", "#{l}.a")
          dst = File.join(c[:output_lib_dir], "#{l}_s.a")
          puts "copying from #{src} to #{dst}"
          FileUtils.cp(src, dst, :verbose => true)
        end
      end

      puts "Installing openssl binary..."
      exeSuffix = c[:platform] == :Windows ? ".exe" : ""
      FileUtils.cp(File.join("bin", "openssl#{exeSuffix}"),
                   File.join(c[:output_bin_dir], "openssl#{exeSuffix}"),
                   :verbose => true)
    }
  },

  :post_install_common => lambda { |c|
    Dir.chdir(c[:build_dir]) {
      puts "Installing headers..."
      FileUtils.cp_r(File.join("include", "openssl"),
                     c[:output_inc_dir], :verbose => true)
      
      puts "Installing openssl.cnf..."
      sslDir = File.join(c[:output_dir], "ssl")
      FileUtils.mkdir_p(sslDir)
      FileUtils.cp_r(File.join("ssl", "openssl.cnf"), 
                     sslDir, :verbose => true)
    }
  }
}

