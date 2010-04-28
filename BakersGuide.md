The Baker's Guide
=================

This document is a guide for would be bakers, folks who wish to make it so new libraries
or tools can be built via the bakery.

The Recipe - A brief walkthrough
--------------------------------

In the bakery, ports are called "recipes", that is, a set of instructions for how to get 
a pile of source code and to turn it into something we can use.  Here's a complete, unabridged
recipe (for YAJL, a popular json parsing library), this file is stored in a directory named
'yajl', in a file named 'recipe.rb':

XXX: consider a simpler example.  hello world?

    {
      :url => 'http://github.com/downloads/lloyd/yajl/yajl-1.0.9.tar.gz',
      :md5 => '8643ff2fef762029e51c86882a4d0fc6',
      :configure => lambda { |c|
        btstr = c[:build_type].to_s.capitalize
        cmakeGen = nil
        # on windows we must specify a generator, we'll get that from the
        # passed in configuration
        cmakeGen = "-G \"#{c[:cmake_generator]}\"" if c[:cmake_generator]
        cmLine = "cmake -DCMAKE_BUILD_TYPE=\"#{btstr}\" " +
                       "-DCMAKE_INSTALL_PREFIX=\"#{c[:output_dir]}\" " +
                       " #{c[:cmake_args]} " +
                       " #{cmakeGen} \"#{c[:src_dir]}\""
        puts cmLine
        system(cmLine)
      },
      :build => {
        :Windows => lambda { |c|
          buildStr = c[:build_type].to_s.capitalize
          system("devenv YetAnotherJSONParser.sln /Build #{buildStr}")
        },
        [ :MacOSX, :Linux ] => "make"
      },
      :install => {
        :Windows => lambda { |c|
          Dir.glob(File.join(c[:build_dir], "yajl-1.0.9", "*")).each { |d|
            FileUtils.cp_r(d , c[:output_dir])
          }
        },
        [ :Linux, :MacOSX ] => "make install"
      },
      :post_install => {
        [ :Linux, :MacOSX ] => lambda { |c|
          system("make install")
    
          # now let's move output to the appropriate place
          # i.e. move from lib/libfoo.a to lib/debug/libfoo.a
          Dir.glob(File.join(c[:output_dir], "lib", "*")).each { |f|
            FileUtils.mv(f, c[:output_lib_dir]) if !File.directory? f
          }
        }
      },
      :post_install_common => lambda { |c|
        Dir.glob(File.join("src", "api", "*")).each { |f|
          FileUtils.cp(f, c[:output_inc_dir])
        }
      }
    }

If you're at all familiar with ruby, the first thing to notice is that this file is
valid ruby code.  It's a hash with various top level symbols.  First notice the `:url` and
`:md5` keys.  These should be self explanatory, and tell the bakery the location of the
software and provide a digest so we can verify the integrity of the source once fetched.

Subsequent to fetching software, there are a series of build steps that the recipe author
may leverage to get their software built.  Each build phase occurs in a specific location and 
is passed a number of arguments (the interesting parameter is named 'c' above, for 'config').
Scanning the above file you'll see `:configure`, `:build`, `:install`, `:post_install`, and
`:post_install_common`.  For each build phase you may specify a string (corresponding to a  
shell command to execute to run the phase) or a function.  Further, you may specify different
code blocks for different platforms by defining the implementation (value) of a build phase 
as a map, where the subkeys are the platform (single symbol), or platforms (array of symbols)
that the build step applies to. 

The Recipe - By build phase
---------------------------

### `:post_patch`

#### intent

#### working directory

#### arguments

### `:pre_build`

### `:configure`

### `:build`

### `:install`

### `:post_install`

### `:post_install_common`

Testing your recipe with driver.rb
----------------------------------

The "Work Directory" and checking out what happened
----------------------------------------

Bakery Layout Conventions
-------------------------

### include layout

### build type support

Patching
--------
