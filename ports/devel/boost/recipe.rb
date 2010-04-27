{
  :url => "http://downloads.sourceforge.net/boost/boost_1_42_0.tar.bz2",
  :md5 => "7bf3b4eb841b62ffb0ade2b82218ebe6",
  :configure => lambda { |c|
    # for the configure step we'll build bjam
    bjamSrcPath = File.join(c[:src_dir], "tools", "jam", "src")
    Dir.chdir(bjamSrcPath) do
      puts "building bjam..."
      if c[:platform] == :Windows
        bjbb = File.join(bjamSrcPath, "build.bat")
        system(bjbb)
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
      if c[:platform] == :MacOSX
        toolset="darwin"
        # add a user-config.jam for Darwin to allow 10.4 compatibility
        uconfig = File.new("user-config.jam", "w")
        uconfig.write("# Boost.Build Configuration\n")
        uconfig.write("# Allow Darwin to build with 10.4 compatibility\n")
        uconfig.write("\n")
        uconfig.write("# Compiler configuration\n")
        uconfig.write("using darwin : 4.0 : g++-4.0 -arch i386 : ")
        uconfig.write("<compileflags>\"#{c[:os_compile_flags]}\" ")
        uconfig.write("<architecture>\"x86\" ")
        uconfig.write("<linkflags>\"#{c[:os_link_flags]}\" ;\n")
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
      rpToBuildDir = Pathname.new(c[:build_dir]).relative_path_from(Pathname.pwd).to_s
      baseCmd += " --abbreviate-paths --build-dir=#{rpToBuildDir} stage"
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
    puts "copying headers..."
    Dir.glob(File.join(c[:src_dir], "boost", "*")).each { |h|
      FileUtils.cp_r(h, c[:output_inc_dir], :verbose => true)
    }

    # copy static libs
    buildType = c[:build_type].to_s.gsub(/[aeiou]/, "")
    puts "copying #{buildType} libraries..."

    libSuffix = ((c[:platform] == :Windows) ? "lib" : "a")
    
    Dir.glob("**/#{buildType}/**/libboost*.#{libSuffix}").each do |l|
      FileUtils.cp(l, c[:output_lib_dir], :verbose => true)
    end
  }
}
