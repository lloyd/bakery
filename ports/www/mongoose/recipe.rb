{
  :url => 'http://mongoose.googlecode.com/files/mongoose-2.8.tgz',
  :md5 => 'b72e937a356d3f3cd80cfe6653f0168d',
  :configure => lambda { |c|
    # configuration is making a local copy of source.  why not?
    Dir.glob(File.join(c[:src_dir], "*")).each { |f|
      FileUtils.cp_r(f, c[:build_dir])
    }
  },
  :build => {
    :Windows => lambda { |c|
      cflags = "-DNO_CGI -DNO_SSL -DNO_SSI"
      cflags += " -nologo -Os"
      cflags += (c[:build_type] == :debug) ? " -Zi -DDEBUG -D_DEBUG -MTd" : " -DNDEBUG -MT"
      system("nmake CL_FLAGS=\"#{cflags}\" msvc")
    },
    [ :MacOSX, :Linux ] => lambda { |c|
      cflags = " -Wall"
      cflags += (c[:build_type] == :debug) ? " -g -O0" : " -O2"
      ENV['CFLAGS'] = cflags
      system("make unix")
    }
  },
  :install => {
    :Windows => lambda { |c|
    },
    [ :MacOSX, :Linux ] => lambda { |c|
      FileUtils.cp("libmongoose_s.a", c[:output_lib_dir])
    }
  },
  :post_install_common => {
    [ :MacOSX, :Linux ] => lambda { |c|
      FileUtils.cp("mongoose.h", c[:output_inc_dir])
    }
  }
}
