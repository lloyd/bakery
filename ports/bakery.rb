# The top level include file for the bakery 

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
    @use_source = order[:use_source]
    @use_recipe = order[:use_recipe]
    @cache_dir = File.join(ENV['HOME'], ".bakery_pkgcache")
  end
  
  def build
    puts "building #{@packages.length} packages:" if @verbose
    @packages.each { |p|
      recipe = @use_recipe[p] if @use_recipe && @use_recipe.has_key?(p) 
      puts "--- building #{p}#{recipe ? (" (" + recipe + ")") : ""} ---" if @verbose      
      b = Builder.new(p, @verbose, @output_dir, @cmake_generator, @cache_dir, recipe)
      if !b.needsBuild
        puts "  - skipping #{p}, already built!" if @verbose              
        next
      end
      puts "  - cleaning #{p}" if @verbose      
      b.clean
      # if we've got the built bits in the cache, then let's use em
      # and call it a day!
      puts "  - checking cache for built pkg" if @verbose
      if b.install_from_cache
        puts "      Installed from cache!  all done." if @verbose
        return
      # if use_source is specified for this package it short circuts
      # fetch and unpack
      elsif @use_source && @use_source.has_key?(p)
        puts "  - copying local source for #{p} (#{@use_source[p]})" if @verbose      
        b.use_source @use_source[p]
      else 
        puts "  - fetching #{p}" if @verbose      
        b.fetch
        puts "  - unpacking #{p}" if @verbose      
        b.unpack
      end
      puts "  - patching #{p}" if @verbose      
      b.patch
      puts "  - post-patch #{p}" if @verbose      
      b.post_patch
      @build_types.each { |bt|
        puts "  - pre_build step for #{p} (#{bt})" if @verbose      
        b.pre_build bt
        puts "  - configuring #{p} (#{bt})" if @verbose      
        b.configure
        puts "  - building #{p} (#{bt})" if @verbose      
        b.build
        puts "  - installing #{p} (#{bt})" if @verbose      
        b.install
        puts "  - running post_install for #{p} (#{bt})" if @verbose      
        b.post_install
      }
      puts "  - running post_install_common for #{p}" if @verbose      
      b.post_install_common
      puts "  - cleaning up #{p}" if @verbose      
      b.dist_clean
      puts "  - Writing receipt for #{p}" if @verbose      
      b.write_receipt
      puts "  - Saving #{p} build output to cache (#{@cache_dir})" if @verbose      
      b.save_to_cache
    }
  end
end
