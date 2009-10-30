require 'uri'
require 'rbconfig'
require 'fileutils'
require 'open-uri'
require 'digest/md5'
include Config

class Builder
  def __checkSym map, sym
    if !map || !map.has_key?(sym)
      throw "recipe for #{@pkg} is incomplete: missing ':#{sym}' key"
    end
  end

  def initialize pkg, verbose, output_dir, cmake_gen
    @pkg = pkg
    @verbose = verbose

    # capture the top level portDir
    @port_dir = File.expand_path(File.dirname(File.dirname(__FILE__)))

    # try to locate the pkg
    locations = [ File.join(@port_dir, pkg, "recipe.rb") ] +
                Dir.glob(File.join(@port_dir, "*", pkg, "recipe.rb"))
    locations.each { |x|
      x = File.expand_path x
      @recipe_path = x if (File.readable? x)
    }
    throw "unknown package: #{pkg}" if !@recipe_path

    # now let's read and parse the recipe
    @recipe = eval(File.read(@recipe_path))
    [ :url, :md5 ].each { |sym|
      __checkSym @recipe, sym
    }

    @distfiles_path = File.join(@port_dir, "distfiles")
    FileUtils.mkdir_p(@distfiles_path)

    @workdir_path = File.join(@port_dir, "work", @pkg)
    FileUtils.mkdir_p(@workdir_path)

    @output_dir = output_dir ? output_dir : File.join(@port_dir, "dist")
    FileUtils.mkdir_p(@output_dir)    

    tarball = File.basename(URI.parse(@recipe[:url]).path)
    @tarball = File.expand_path(File.join(@distfiles_path, tarball))

    #let's determine the platform
    if CONFIG['arch'] =~ /mswin/
      @platform = :Windows
      @sevenZCmd = File.expand_path(File.join(@port_dir, "WinTools", "7z.exe"))
      @cmake_generator = "Visual Studio 9 2008"
    elsif CONFIG['arch'] =~ /darwin/
      @platform = :MacOSX
    elsif CONFIG['arch'] =~ /linux/
      @platform = :Linux
    end

    @cmake_generator = cmake_gen if cmake_gen
    
    #build up the configuration object that will be passed into build functions
    @conf = {
      :platform => @platform,
      :output_dir => @output_dir,
      :cmake_generator => @cmake_generator
    }
  end
  
  def needsBuild
    true
  end

  def clean
    puts "      removing previous build artifacts (#{@workdir_path})..."
    FileUtils.rm_rf(@workdir_path)
    FileUtils.mkdir_p(@workdir_path)
  end

  def checkMD5 
    match = false
    if File.readable? @tarball
      # now let's check the md5 sum
      calculated_md5 = Digest::MD5.hexdigest(
                         File.open(@tarball, "rb") { |f| f.read })
      match = (calculated_md5 == @recipe[:md5])
    end
    match
  end

  def fetch
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
              system("bzcat #{path} | tar xf -")
            elsif File.extname(path) == ".gz"
              system("tar xzf #{path}")
            else
              throw "unrecognized format for #{path}"
            end
          end
        elsif path =~ /.tgz/
          if @platform == :Windows
            system("#{@sevenZCmd} x #{path}")
          else
            system("tar xzf #{path}")
          end
        elsif path =~ /.zip/
          if @platform == :Windows
            system("#{@sevenZCmd} x #{path}")
          else
            system("tar xzf #{path}")
          end
        else
          throw "unrecognized format for #{path}"
        end
      end
    end

    # now we have what we need to determine the unpack dirname
    Dir.glob(File.join(srcPath, "*")).each { |d|
      @unpack_dir = d if File.directory? d
    }
    puts "      unpacked to #{@unpack_dir}"
    
    @conf[:src_dir] = @unpack_dir 
  end

  def patch
    # XXX: implement me
  end

  def pre_build buildType
    # make the build directory and set up our conf
    @conf[:build_type] = buildType
    @build_dir = File.join(@workdir_path, "build_" + buildType.to_s)
    FileUtils.mkdir_p(@build_dir)    
    @conf[:build_dir] = @build_dir
  end

  def __redirectOutput fName 
    File.open(fName, "w") { |f|    
      # redirect stderr and stdout
      old_stdout = $stdout.dup
      old_stderr = $stderr.dup
      $stdout.reopen(f)
      $stderr.reopen(f)
      yield
      $stdout.reopen(old_stdout)
      $stderr.reopen(old_stderr)
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
      runBuildPhase2 phase, &b 
    end
    Process.wait
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
      if obj[sym].kind_of?(Hash)
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

  def dist_clean
  end
end
