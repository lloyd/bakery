require File.join(File.dirname(__FILE__), 'Impl', 'builder')

class Bakery
  @@distfiles_dir = File.join(File.dirname(__FILE__), "distfiles")
  @@work_dir = File.join(File.dirname(__FILE__), "work")

  def initialize order
    throw "improper order passed to Bakery.new!" if !order
    @build_types = [ :debug, :release ]
    @verbose = (order && order[:verbose])
    @output_dir = File.join(File.dirname(__FILE__), "dist")
    @output_dir = order[:output_dir] if (order && order[:output_dir])
    @output_dir = File.expand_path(@output_dir)
    throw "now packages specified in order" if !order[:packages]
    @packages = order[:packages]
    @cmake_generator = (order && order[:cmake_generator])
  end
  
  def build
    puts "building #{@packages.length} packages:" if @verbose
    @packages.each { |p|
      puts "--- building #{p} ---" if @verbose      
      b = Builder.new(p, @verbose, @output_dir, @cmake_generator)
      if !b.needsBuild
        puts "    skipping #{p}, already built!" if @verbose              
        next
      end
      puts "    cleaning #{p}" if @verbose      
      b.clean
      puts "    fetching #{p}" if @verbose      
      b.fetch
      puts "    unpacking #{p}" if @verbose      
      b.unpack
      puts "    patching #{p}" if @verbose      
      b.patch
      @build_types.each { |bt|
        puts "    pre_bulid step for #{p} (#{bt})" if @verbose      
        b.pre_build bt
        puts "    configuring #{p} (#{bt})" if @verbose      
        b.configure
        puts "    building #{p} (#{bt})" if @verbose      
        b.build
        puts "    installing #{p} (#{bt})" if @verbose      
        b.install
      }
      puts "    running post_install for #{p}" if @verbose      
      b.post_install
      puts "    cleaning up #{p}" if @verbose      
      b.dist_clean
    }
  end
end
