{
  :url => 'http://github.com/downloads/lloyd/bakery/nodejs-lloyd_v1.tar.bz2',
  :md5 => '3b471b6431a45ed2c5bad1af8a8bb148',
  :configure => {
    :Windows => lambda { |c|
      raise "not yet ported to windows"
    },
    [:Linux, :MacOSX] => lambda { |c|
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

      # only copy headers once
      if c[:build_type] == :release
        # copy in node headers
        Dir.glob(File.join(c[:build_dir], "src", "node*.h")).each { |f|
          FileUtils.cp(f, c[:output_inc_dir], :preserve => true)
        }
      
        # copy in v8 headers
        Dir.glob(File.join(c[:build_dir], "deps", "v8", "include", "v8*.h")).each { |f|
          FileUtils.cp(f, c[:output_inc_dir], :preserve => true)
        }

        # rewrite inclusion paths so that clients will include as "nodejs/v8.h"
        Dir.glob(File.join(c[:output_inc_dir], "*.h")).each { |f|
          contents = File.read(f)
          contents.gsub!(/^#include\s+<((?:v8|node)[a-zA-Z_]*\.h)>/, '#include <nodejs/\1>')
          File.open("#{f}", "w+") { |nf| nf.write contents }
        }
      end
    }      
  }
}

