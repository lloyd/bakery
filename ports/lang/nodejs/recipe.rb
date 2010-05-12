{
  :url => 'http://github.com/downloads/lloyd/bakery/nodejs-lloyd_v3.tar.bz2',
  :md5 => '9da3810aeb2b1623951b2bea4b08b25d',
  :deps => [ 'openssl', 'zlib' ],
  :configure => {
    :Windows => lambda { |c|
      raise "not yet ported to windows"
    },
    [:Linux, :MacOSX] => lambda { |c|
      ENV['CFLAGS'] = "#{c[:os_compile_flags]} #{ENV['CFLAGS']}"
      ENV['CXXFLAGS'] = "#{c[:os_compile_flags]} #{ENV['CXXFLAGS']}"
      ENV['CFLAGS'] += ' -g -O0 ' if c[:build_type] == :debug
      ENV['CXXFLAGS'] += ' -g -O0 ' if c[:build_type] == :debug
      ENV['LDFLAGS'] = "#{c[:os_link_flags]} #{ENV['LDFLAGS']}"

      # make sure that the build can find the correct openssl libs 
      # (not system libs)
      ENV['BAKERY_LIBPATH'] = c[:output_lib_dir]

      # pkg doesn't support out of source builds, make a local copy 
      Dir.glob(File.join(c[:src_dir], "*")).each { |f|
        FileUtils.cp_r(f, c[:build_dir], :preserve => true)
      }
      system(File.join(c[:build_dir], "configure"))
    }
  },
  :build => {
    :Windows => lambda { |c|
      raise "not yet ported to windows"
    },
    [:Linux, :MacOSX] => "make"
  },
  :install => { 
    :Windows => lambda { |c|
      raise "not yet ported to windows"
    },
    [:Linux, :MacOSX] => lambda { |c|
      # copy in static libraries (appending _s to follow bakery conventions)
      Dir.glob(File.join(c[:build_dir], "**", "lib*.a")).each { |f|
        newName = File.basename(f).sub(/.a$/, '_s.a')  
        FileUtils.cp(f, File.join(c[:output_lib_dir], newName), :preserve => true)
      }        

      # copy in binary (appending build type to name)
      newName = "node_#{c[:build_type].to_s}"
      FileUtils.cp("node", File.join(c[:output_bin_dir], newName))      

      # only copy headers once
      if c[:build_type] == :release
        # copy in node headers
        Dir.glob(File.join(c[:build_dir], "src", "node*.h")).each { |f|
          FileUtils.cp(f, c[:output_inc_dir], :preserve => true)
        }

        # and generated headers (like node_version.h)
        Dir.glob(File.join(c[:build_dir], "build",
                           "default", "src", "node*.h")).each { |f|
          FileUtils.cp(f, c[:output_inc_dir], :preserve => true)
        }

        # copy in v8 headers
        Dir.glob(File.join(c[:build_dir], "deps", "v8", "include", "v8*.h")).each { |f|
          FileUtils.cp(f, c[:output_inc_dir], :preserve => true)
        }

        # and eio.h and ev.h ...  data_hiding--
        FileUtils.cp(File.join(c[:build_dir], "deps", "libev", "ev.h"),
                     c[:output_inc_dir], :preserve => true)
        FileUtils.cp(File.join(c[:build_dir], "deps", "libeio", "eio.h"),
                     c[:output_inc_dir], :preserve => true)

        # rewrite inclusion paths so that clients will include as "nodejs/v8.h"
        Dir.glob(File.join(c[:output_inc_dir], "*.h")).each { |f|
          contents = File.read(f)
          contents.gsub!(/^#include\s+<((?:ev|eio|v8|node)[a-zA-Z_]*\.h)>/, '#include <nodejs/\1>')
          File.open("#{f}", "w+") { |nf| nf.write contents }
        }
      end
    }      
  }
}

