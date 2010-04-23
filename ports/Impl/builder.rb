require 'yaml'
require 'set'
require 'uri'
require 'rbconfig'
require 'fileutils'
require 'open-uri'
require 'digest/md5'
include Config

alias actual_system system

def system *args
#  puts "system(\"#{args.join('", "')}\")"
  rv = actual_system(*args)
  raise "system invocation failed (#{args.join(' ')})" if !rv
  raise "system call returned non success: #{$?}" if $? != 0
  return rv
end

class Builder
  def __checkSym map, sym
    if !map || !map.has_key?(sym)
      throw "recipe for #{@pkg} is incomplete: missing ':#{sym}' key"
    end
  end

  def initialize pkg, verbose, output_dir, cmake_gen, cache_dir, recipe_location = nil
    @pkg = pkg
    @verbose = verbose
    @cache_dir = cache_dir

    # capture the top level portDir
    @port_dir = File.expand_path(File.dirname(File.dirname(__FILE__)))

    # try to locate the pkg
    locations = [
                 recipe_location,
                 File.join(@port_dir, pkg, "recipe.rb")
                ] +
      Dir.glob(File.join(@port_dir, "*", pkg, "recipe.rb"))

    @recipe_path = nil
    locations.each { |x|
      next if @recipe_path != nil || x == nil || !File.readable?(x)
      @recipe_path = File.expand_path(x)
      break
    }
    throw "unknown package: #{pkg}" if !@recipe_path

    @recipe_dir = File.expand_path(File.dirname(@recipe_path))

    # now let's read and parse the recipe
    @recipe = eval(File.read(@recipe_path))
#    [ :url, :md5 ].each { |sym|
#      __checkSym @recipe, sym
#    }

    @distfiles_path = File.join(@port_dir, "distfiles")
    FileUtils.mkdir_p(@distfiles_path)

    @workdir_path = File.join(@port_dir, "work", @pkg)
    FileUtils.mkdir_p(@workdir_path)

#    @logdir_path = File.join(@workdir_path, "logs")
#    FileUtils.mkdir_p(@logdir_path)

    @output_dir = output_dir ? output_dir : File.join(@port_dir, "dist")
    FileUtils.mkdir_p(@output_dir)    

    # now let's ensure the include dir exists
    @output_inc_dir = File.join(@output_dir, "include", @pkg)
    FileUtils.mkdir_p(@output_inc_dir)    

    @output_bin_dir = File.join(@output_dir, "bin")
    FileUtils.mkdir_p(@output_bin_dir)    

    # lib dir will be updated at _pre_build_ time (once per build type)

    @tarball = nil
    if @recipe.has_key?(:url) && @recipe[:url]
      tarball = File.basename(URI.parse(@recipe[:url]).path)
      @tarball = File.expand_path(File.join(@distfiles_path, tarball))
    end

    # initialize OS specific compile/link flags to the empty string
    @os_compile_flags = ""
    @os_link_flags = ""

    # let's determine the platform
    @patch_cmd = "patch"
    if CONFIG['arch'] =~ /mswin/
      @platform = :Windows
      @platlookup = [ @platform, :All ]
      @sevenZCmd = File.expand_path(File.join(@port_dir, "WinTools", "7z.exe"))
      # on windows, patch is called ptch since an exe named "patch" will
      # cause a UAC on Vista
      @patch_cmd = File.expand_path(File.join(@port_dir, "WinTools", "ptch.exe"))
      @cmake_generator = "Visual Studio 9 2008"
    elsif CONFIG['arch'] =~ /darwin/
      @platform = :MacOSX
      @platlookup = [ @platform, :Unix, :All ]

      # Compiler/linker flags needed for 10.4 compatibility.  The surrounding
      # spaces are important, don't be tempted to remove them.
      #
      # 10.4 compatibility is painful, see 
      # http://developer.apple.com/releasenotes/Darwin/SymbolVariantsRelNotes/index
      # In general, we must get these flags to the compiler and linker to tell it
      # what sdk to use.  In addition, source which defines any of the preprocessor
      # symbols mentioned in the above article will be problematic.
      #
      @os_compile_flags = " -isysroot /Developer/SDKs/MacOSX10.4u.sdk "
      @os_compile_flags += " -mmacosx-version-min=10.4 "
      @os_link_flags = @os_compile_flags
      @os_compile_flags += " -arch i386 "
      if CONFIG['arch'] !~ /darwin8/
        # this flag only exists on 10.5 and later
        @os_link_flags += " -syslibroot,/Developer/SDKs/MacOSX10.4u.sdk "
      end

      # globally update CC/CXX env vars
      ENV['CC'] = 'gcc-4.0'
      ENV['CXX'] = 'g++-4.0'
      @cmake_args = "-DCMAKE_OSX_DEPLOYMENT_TARGET=10.4"
    elsif CONFIG['arch'] =~ /linux/
      @platform = :Linux
      @platlookup = [ @platform, :Unix, :All ]
      @os_compile_flags = " -fPIC "
    end

    @cmake_generator = cmake_gen if cmake_gen
    
    #build up the configuration object that will be passed into build functions
    @conf = {
      :platform => @platform,
      :output_dir => @output_dir,
      :output_inc_dir => @output_inc_dir,
      :output_bin_dir => @output_bin_dir,
      :cmake_generator => @cmake_generator,
      :os_compile_flags => @os_compile_flags,
      :os_link_flags => @os_link_flags,
      :recipe_dir => @recipe_dir
    }

    # where shall our manifest live?
    @receipts_dir = File.join(@output_dir, "receipts")
    FileUtils.mkdir_p(@receipts_dir)
    @receipt_path = File.join(@receipts_dir, "#{@pkg}.yaml")

    # port md5 calculation is expensive.  we only calculate it once per invocation
    # using this member as a cache
    @port_md5 = nil
  end

  def __libdir_contents
    lib_dir = File.join(@output_dir, "lib")
    if File.directory? lib_dir
      Set.new(Dir.chdir(lib_dir){ Dir.glob("**/*").reject { |f| File.directory?(f) } })
    else
      Set.new
    end
  end

  # a "port md5" is a single md5 that captures the state of all files in the
  # ports directory.  if any of them changes, then the port md5 changes too
  # and a rebuild is triggered.  Because a recipe includes the md5 of the
  # contents of the source tarball, this "port md5" is really an md5 over the
  # entire input to the build process, sans environmental factors (env vars,
  # compiler version, etc).  
  def __getPortMD5
    return @port_md5 if @port_md5 != nil

    md5s = Array.new

    Dir.glob(File.join(@recipe_dir, "**", "*")).each{ |f|
      md5s.push __fastMD5(f)    
    }
    @port_md5 = Digest::MD5::hexdigest(md5s.sort.join)
    return @port_md5
  end
  
  def needsBuild
    return true if !File.exist?(@receipt_path)
    
    r = File.open( @receipt_path ) { |yf| YAML::load( yf ) }

    # first, if the recipe contents have changed, or any of the contents inside
    # the port directory (patches, etc), then we need a rebuild.
    # (and we don't care if they've moved, really, it's about contents)
    return true if r[:recipe] != __getPortMD5

    return false
  end

  def check

  end

  def clean
    puts "      removing previous build artifacts (#{@workdir_path})..."
    FileUtils.rm_rf(@workdir_path)
    FileUtils.mkdir_p(@workdir_path)

    # now remove installed artifacts if needed
    if File.exist?(@receipt_path)
      puts "      removing previous build output..."
      r = File.open( @receipt_path ) { |yf| YAML::load( yf ) }
      r[:files].each { |p,md5|
        FileUtils.rm_f(File.join(@output_dir, p), :verbose => true )
      }
      FileUtils.rm_f( @receipt_path )

      # for good measure, let's remove and re-create the header directory
      # (handles nested directories)
      FileUtils.rm_rf( @output_inc_dir )
      FileUtils.mkdir_p( @output_inc_dir )      
    end

    # for purposes of receipts, let's take a snapshot of the lib directory
    @libdir_before = __libdir_contents

    # the total set of files that were installed, populated during write_receipts
    # phase.
    @libs_installed = Array.new
    @incs_installed = Array.new
  end

  def __fastMD5 file
    d = Digest::MD5.new
    chunk = nil
    md5 = nil
    begin
      File.open(file, "rb") { |f|
        while (chunk = f.sysread(4096))
          d.update(chunk)
        end
      }
    rescue EOFError
      d.to_s
    end
  end

  def checkMD5 
    match = false
    if File.readable? @tarball
      # now let's check the md5 sum
      calculated_md5 = __fastMD5 @tarball
      match = (calculated_md5 == @recipe[:md5])
    end
    match
  end

  def fetch
    if !@recipe.has_key?(:url) || !@recipe[:url]
      puts "      nothing to fetch for this port"
      return
    end

    url = @recipe[:url]

    if !checkMD5
      puts "      #{url}"
      perms = @platform == :Windows ? "wb" : "w"
      totalSize = 0
      lastPercent = 0
      interval = 5
      f = File.new(@tarball, perms)
      f.write(open(
          url,
          :content_length_proc => lambda {|t|
              if (t && t > 0)
                totalSize = t
                puts "      reading #{totalSize} bytes..."
                STDOUT.printf("      %% down: ")
                STDOUT.flush
              else
                STDOUT.print("      downloading tarball of unknown size")
              end
           },
           :progress_proc => lambda {|s|
              if (totalSize > 0)
                percent = ((s.to_f / totalSize) * 100).to_i
                if (percent/interval > lastPercent/interval)
                  lastPercent = percent
                  STDOUT.printf("%d ", percent)
                  STDOUT.printf("\n") if (percent == 100)
                end
              else
                STDOUT.printf(".")
              end
              STDOUT.flush
            }).read)
            f.close()
            s = File.size(@tarball)
            if (s == 0 || (totalSize > 0 && s != totalSize))
              FileUtils.rm_f(@tarball)
              throw "download failed (#{url})"
            end
      throw "md5 mismatch on #{@tarball} downloaded from #{url}" if !checkMD5
    else
      puts "      #{File.basename(@tarball)} already in distfiles/ no download required"
    end
  end

  def unpack
    if !@tarball
      puts "      nothing to unpack for this port"
      return
    end
    
    srcPath = File.join(@workdir_path, "src")
    FileUtils.mkdir_p srcPath
    Dir.chdir(srcPath) do
      __redirectOutput(File.join(@workdir_path, "unpack.log")) do
        path = @tarball
        puts "      unpacking #{path}..."
        if path =~ /.tar./
          if @platform == :Windows
            system("#{@sevenZCmd} x #{path}")
            tarPath = File.basename(path, ".*")
            system("#{@sevenZCmd} x #{tarPath}")
            FileUtils.rm_f(tarPath)
          else
            if File.extname(path) == ".bz2"
              system("tar xvjf #{path}")
            elsif File.extname(path) == ".gz"
              system("tar xvzf #{path}")
            else
              throw "unrecognized format for #{path}"
            end
          end
        elsif path =~ /.tgz/
          if @platform == :Windows
            system("#{@sevenZCmd} x #{path}")
            tarPath = File.basename(path, ".*") + ".tar"
            puts "untarring #{tarPath}..."
            system("#{@sevenZCmd} x #{tarPath}")
            FileUtils.rm_f(tarPath)
          else
            system("tar xvzf #{path}")
          end
        elsif path =~ /.zip/
          if @platform == :Windows
            system("#{@sevenZCmd} x #{path}")
          else
            system("tar xvzf #{path}")
          end
        else
          throw "unrecognized format for #{path}"
        end
      end
    end

    # now we have what we need to determine the unpack dirname
    @unpack_dir = srcPath
    Dir.glob(File.join(srcPath, "*")).each { |d|
      @unpack_dir = d if File.directory? d
    }
    puts "      unpacked to #{@unpack_dir}"

    @src_dir = File.expand_path(@unpack_dir)
    @conf[:src_dir] = @src_dir
  end

  def use_source p
    # if path provided is a tarball, we'll set @tarball and pop over
    # into the unpack code.  otherwise if it's a directory we'll
    # copy in the contents.
    if p =~ /\.tar\./ || p =~ /zip$/ || p =~ /tgz$/ 
      @tarball = p
      unpack
    elsif File.directory?(p)
      srcPath = File.join(@workdir_path, "src")
      FileUtils.mkdir_p srcPath

      Dir.glob(File.join(p, "*")).each { |f|
        # skip toplevel dotfiles
        next if f =~ /^\./
        FileUtils.cp_r(f, srcPath)
      }
      
      @src_dir = srcPath
      @conf[:src_dir] = @src_dir
    else
      raise "I don't know how to \"use\" this: #{p}"
    end
  end

  def patch
    patch_log = File.join(@workdir_path, "patch.log")
    FileUtils.rm_f(patch_log)
    portDir = File.dirname(@recipe_path)
    
    # first we'll find patches!
    patches = Array.new

    @platlookup.each do |p|
      patches += Dir.glob(File.join(portDir, "*_#{p.to_s}.patch"))
    end
    patches.sort!
    puts "      Found #{patches.length} patch(es)!"
    patches.each do |p|
      p = File.expand_path(p)
      puts "      Applying #{File.basename(p, ".patch")}"
      __redirectOutput(patch_log, true) do
        puts "output redirected"
        # now let's apply p  
        Dir.chdir(@src_dir) {
          puts "inside src_dir"
          pline = "#{@patch_cmd} -p1 < #{p}"
          puts "executing patch cmd: #{pline}" 
          system(pline)
        }
      end
    end
  end

  def post_patch
    @build_dir = @src_dir # yes martha, that's a hack
    invokeLambda(:post_patch, @recipe, :post_patch)
  end

  def pre_build buildType
    # make the build directory and set up our conf
    @conf[:build_type] = buildType
    @build_dir = File.join(@workdir_path, "build_" + buildType.to_s)
    FileUtils.mkdir_p(@build_dir)    
    @conf[:build_dir] = @build_dir

    # update lib dir
    @output_lib_dir = File.join(@output_dir, "lib", buildType.to_s)
    FileUtils.mkdir_p(@output_lib_dir)
    @conf[:output_lib_dir] = @output_lib_dir
  end

  def __redirectOutput fName, append = false
    File.open(fName, (append ? "a" : "w")) { |f|    
      # redirect stderr and stdout
      old_stdout = $stdout.dup
      old_stderr = $stderr.dup
      $stdout.reopen(f)
      $stderr.reopen(f)
      begin
        yield
      ensure
        $stdout.reopen(old_stdout)
        $stderr.reopen(old_stderr)
      end
    }
  end

  def runBuildPhase2 phase
    # execute in the build dir
    Dir.chdir(@build_dir) {
      __redirectOutput("#{phase}.log") { yield }
    }
  end

  # the ampersand syntax effectively relays our callers block/closure
  # to runBuildPhaseTwo
  def runBuildPhase phase, &b
    # fork doesn't exist on windows, but likewise on windows it's less
    # common to actually use the environment, so there's less of a need
    # for the isolation that forking provides us.  If the fork raises
    # NotImplementedError we'll just fallback to non-forking mode
    fork do
      begin
        runBuildPhase2 phase, &b 
      rescue => e
        STDERR.puts "CAUGHT EXCEPTION during #{phase.to_s} phase: #{e.to_s}"
        exit 1
      end
    end
    Process.wait
    raise "build failed" if $?.exitstatus != 0
  rescue NotImplementedError
    runBuildPhase2 phase, &b    
  end
    
  def invokeLambda step, obj, sym
    # support arrays as keys in recipes for user conveneince, i.e.:
    #  [:Linux, :MacOSX] => "make"
    # essentially what we do is iterate through all recipe
    if obj && !obj.has_key?(sym)
      obj.each { |k,v|
        sym = k if (k.kind_of?(Array) && k.include?(sym))
      }
    end      

    if obj && obj.has_key?(sym)
      if obj[sym] == nil
        puts "      (not required on this platform)"
      elsif obj[sym].kind_of?(Hash)
        invokeLambda(step, obj[sym], @platform)
      elsif obj[sym].kind_of?(String)
        runBuildPhase(step.to_s) {
          system(obj[sym])
        }
      elsif obj[sym].kind_of?(Proc)
        runBuildPhase(step.to_s) { obj[sym].call @conf }
      else
        throw "invalid recipe file (handling #{sym})"
      end
    else 
      puts "      WARNING: #{step} step not supplied!"
    end
  end

  def configure
    invokeLambda(:configure, @recipe, :configure)
  end

  def build
    invokeLambda(:build, @recipe, :build)
  end

  def install
    invokeLambda(:install, @recipe, :install)
  end

  def post_install
    invokeLambda(:post_install, @recipe, :post_install)
  end

  def post_install_common
    @build_dir = @src_dir # yes martha, that's a hack
    invokeLambda(:post_install_common, @recipe, :post_install_common)
  end

  def dist_clean
  end

  def write_receipt
    sigs = Hash.new
    @libs_installed = Array.new
    __libdir_contents.subtract(@libdir_before).each { |l|
      l = File.join("lib", l)
      @libs_installed.push l
      md5 = __fastMD5(File.join(@output_dir, l))
      sigs[l] = md5
    }

    @incs_installed = Array.new
    Dir.chdir(@output_inc_dir) { Dir.glob("**/*").each { |h|
        next if File.directory? h
        h = File.join("include", @pkg, h)
        @incs_installed.push h
        md5 = __fastMD5(File.join(@output_dir, h))
        sigs[h] = md5
    } }
    rf = {
      :recipe => __getPortMD5(),
      :files => sigs.sort
    }
    File.open(@receipt_path, "w") { |r| YAML.dump(rf, r) }
  end

  def save_to_cache
    FileUtils.mkdir_p(@cache_dir)
    tmpfname = File.join(@cache_dir, "#{@pkg}-#{__getPortMD5()}.tar")
    fname = File.join(@cache_dir, "#{@pkg}-#{__getPortMD5()}.tgz")
    FileUtils.rm_f(tmpfname)
    FileUtils.rm_f(fname)
    Dir.chdir(@output_dir) {
      cmdline = (@incs_installed | @libs_installed).map { |i| i.gsub(/([" ])/, "\\\1") }.join(" ") 
      if @platform == :Windows
        system("7z a -ttar #{tmpfname.gsub(/([" ])/, "\\\1")} #{cmdline}")        
        system("7z a -tgzip #{fname.gsub(/([" ])/, "\\\1")} #{tmpfname.gsub(/([" ])/, "\\\1")}")        
        FileUtils.rm_f(tmpfname)
      else
        system("tar czf #{fname.gsub(/([" ])/, "\\\1")} #{cmdline}")
      end
    }
    puts "      #{File.size(fname) / 1024}kb saved to #{File.basename(fname)}"
  end
end
