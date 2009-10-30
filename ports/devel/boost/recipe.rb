
{
  :url => "http://downloads.sourceforge.net/boost/boost_1_39_0.tar.bz2",
  :md5 => "a17281fd88c48e0d866e1a12deecbcc0",
  :configure => lambda { |c|
    # for the configure step we'll build bjam
    bjamSrcPath = File.join(c[:src_dir],"tools", "jam", "src")
    Dir.chdir(bjamSrcPath) do
      puts "building bjam..."
      if c[:platform] == :Windows
        system(".\\build.bat")
      else 
        system("./build.sh")
      end
    end
  },
  :build => lambda { |c|
    # run the build from the src_dir
    Dir.chdir(c[:src_dir]) { 
      buildLibs = %w(system filesystem)
      buildLibs.insert(-1, "regex") if c[:platform] != :Windows

      # now hunt down the built bjam from our configure step
      bjamSrcPath = File.join("tools", "jam", "src")
      bjamPath = Dir.glob("#{bjamSrcPath}/bin.*/**/bjam*")[0]

      toolset=""
      if c[:platform] == :Darwin
        toolset="darwin"
        # add a user-config.jam for Darwin to allow 10.4 compatibility
        uconfig = File.new("user-config.jam", "w")
        uconfig.write("# Boost.Build Configuration\n")
        uconfig.write("# Allow Darwin to build with 10.4 compatibility\n")
        uconfig.write("\n")
        uconfig.write("# Compiler configuration\n")
        uconfig.write("using darwin : 4.0 : g++-4.0 -arch i386 : ")
        uconfig.write("<compileflags>\"#{$darwinCompatCompileFlags}\" ")
        uconfig.write("<architecture>\"x86\" ")
        uconfig.write("<linkflags>\"#{$darwinCompatLinkFlags}\" ;\n")
        uconfig.close
        
      elsif c[:platform] == :Windows
        toolset="msvc"
      elsif c[:platform] == :Linux
        toolset="gcc"
      else
        throw "Unsupported platform #{c[:platform].to_s}"
      end

      # now use bjam to build 
      baseCmd = "#{bjamPath} toolset=#{toolset} "
      baseCmd += " link=static threading=multi runtime-link=static"
      baseCmd += " --build-dir=#{c[:build_dir]} stage"
      if c[:platform] == :MacOSX
        baseCmd += " --user-config=user-config.jam"
      end

      buildType = c[:build_type].to_s
      buildLibs.each() do |l|
        puts "building #{buildType} #{l}..."
        buildCmd = baseCmd + " variant=#{buildType} --with-#{l}"
        puts buildCmd
        system(buildCmd)
      end
    }
  },
  :install => lambda { |c|
    
  }
}
