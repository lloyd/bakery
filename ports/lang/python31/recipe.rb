{
  :url => "http://www.python.org/ftp/python/3.1.2/Python-3.1.2.tar.bz2",
  :md5 => "45350b51b58a46b029fb06c61257e350",
  :configure => {
    [ :Linux, :MacOSX ] => lambda { |c|
      if $platform == :MacOSX
        ENV['CFLAGS'] = "#{c[:os_compile_flags]} #{ENV['CFLAGS']}"
        ENV['LDFLAGS'] = "#{c[:os_link_flags]} #{ENV['LDFLAGS']}"
      end
      if c[:build_type] == :debug
        ENV['CFLAGS'] = "-g -O0 #{ENV['CFLAGS']}"
      end
      configScript = File.join(c[:src_dir], "configure")
      configstr = "#{configScript} --enable-shared --enable-universalsdk --prefix=#{c[:output_dir]} "
      puts "running configure: #{configstr}"
      system(configstr)
    }, 
    [ :Windows ] => lambda { |c|
#      ENV['RUNTIMEFLAG'] = '-MT'
#      # XXX: add openssl and zlib
#      ENV['EXTS'] = "bigdecimal,continuation,coverage,digest,digest/md5,digest/rmd160,digest/sha1,digest/sha2,dl,fcntl,fiber,json,mathn,nkf,racc/cparse,ripper,sdbm,socket,stringio,strscan,syck,win32ole" 
#      # grrr.  make a copy
#      Dir.glob(File.join(c[:src_dir], "*")).each { |f| FileUtils.cp_r(f, ".") }
#      configScript = File.join(c[:src_dir], "win32\\configure.bat")
#      configstr = "#{configScript} --prefix=#{c[:output_dir].gsub('/', '\\')} "
#      configstr = configstr + "--disable-install-doc"
#      puts "running configure: #{configstr}"
#      system(configstr)
    }
  },
  :build => {
    [ :Linux, :MacOSX ] => "make",
    [ :Windows ] => lambda { |c|
#      ENV['OLD_PATH'] = "#{ENV['PATH']}"
#      ENV['PATH'] = "#{ENV['PATH']};#{c[:wintools_dir].gsub('/', '\\')}\\bin"
#      system("nmake")
#      ENV['PATH'] = "#{ENV['OLD_PATH']}"
    }
  },
  :install => {
    [ :Linux, :MacOSX ] => lambda { |c|
      system("make install")
      # now move output in lib dir into build config dir
      Dir.glob(File.join(c[:output_dir], "lib", "*python*")).each { |l|
        tgtBasename = File.basename(l)
        tgt = File.join(c[:output_lib_dir], tgtBasename)
        FileUtils.mv(l, tgt, :verbose => true)
      }
      Dir.glob(File.join(c[:output_dir], "lib", "pkgconfig")).each { |l|
        tgtBasename = File.basename(l)
        tgt = File.join(c[:output_lib_dir], tgtBasename)
        FileUtils.mv(l, tgt, :verbose => true)
      }
    },
    [ :Windows ] => lambda { |c|
#      ENV['OLD_PATH'] = "#{ENV['PATH']}"
#      ENV['PATH'] = "#{ENV['PATH']};#{c[:wintools_dir].gsub('/', '\\')}\\bin"
#      system("nmake install")
#      ENV['PATH'] = "#{ENV['OLD_PATH']}"
#      # now move output in lib dir into build config dir
#      Dir.glob(File.join(c[:output_dir], "lib", "*python*")).each { |l|
#        tgtBasename = File.basename(l)
#        tgt = File.join(c[:output_lib_dir], tgtBasename)
#        FileUtils.mv(l, tgt, :verbose => true)
#      }
    }
  },
  :post_install_common => {
    [ :Linux, :MacOSX ] => lambda { |c|
      py31dir = File.join(c[:output_dir], "include", "python3.1")
      Dir.glob(File.join(py31dir, "*")).each { |h|
        FileUtils.mv(h, c[:output_inc_dir], :verbose => true)
      }
      FileUtils.rmdir(py31dir)
    },
    [ :Windows ] => lambda { |c|
#      py31dir = File.join(c[:output_dir], "include", "python3.1")
#      Dir.glob(File.join(py31dir, "*")).each { |h|
#        FileUtils.mv(h, c[:output_inc_dir], :verbose => true)
#      }
#      FileUtils.rmdir(py31dir)
    }
  }
}
