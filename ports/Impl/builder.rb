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

  def initialize pkg, verbose
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

    tarball = File.basename(URI.parse(@recipe[:url]).path)
    @tarball = File.expand_path(File.join(@distfiles_path, tarball))
  end

  def needsBuild
    true
  end

  def clean
    puts "      removing previous build artifacts..."
    FileUtils.rm_f(@workdir_path)
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
    return match
  end

  def fetch
    url = @recipe[:url]

    if !checkMD5
      puts "      #{url}"
      perms = $platform == "Windows" ? "wb" : "w"
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
    Dir.chdir(@workdir_path) do
      path = @tarball
      puts "      unpacking #{path}..."
      if path =~ /.tar./
        if $platform == "Windows"
          system("#{$sevenZCmd} x #{path}")
          tarPath = path[0, path.rindex('.')]
          system("#{$sevenZCmd} x #{tarPath}")
          FileUtils.rm_f(tarPath)
        else
          if File.extname(path) == ".bz2"
            system("bzcat #{path} | tar xf -")
          elsif File.extname(path) == ".gz"
            system("tar xzf #{path}")
          else
            puts "unrecognized format for #{path}"
            exit -1
          end
        end
      elsif path =~ /.tgz/
        if $platform == "Windows"
          system("#{$sevenZCmd} x #{path}")
        else
          system("tar xzf #{path}")
        end
      elsif path =~ /.zip/
        if $platform == "Windows"
          system("#{$sevenZCmd} x #{path}")
        else
          system("tar xzf #{path}")
        end
      else
        puts "unrecognized format for #{path}"
        exit -1
      end
    end
  end

  def patch
  end

  def pre_build
  end

  def build buildType
  end

  def install buildType
  end

  def post_install
  end

  def dist_clean
  end
end
