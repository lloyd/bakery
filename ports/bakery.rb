# The top level include file for the bakery 

require File.join(File.dirname(__FILE__), 'Impl', 'builder')
require File.join(File.dirname(__FILE__), 'Impl', 'build_timer')

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
    log_with_time "building #{@packages.length} packages:" if @verbose
    @packages.each { |p|
      recipe = @use_recipe[p] if @use_recipe && @use_recipe.has_key?(p) 
      log_with_time "--- building #{p}#{recipe ? (" (" + recipe + ")") : ""} ---" if @verbose      
      b = Builder.new(p, @verbose, @output_dir, @cmake_generator, @cache_dir, recipe)
      if !b.needsBuild
        log_with_time "  - skipping #{p}, already built!" if @verbose              
        next
      end
      log_with_time "  - cleaning #{p}" if @verbose      
      b.clean
      # if we've got the built bits in the cache, then let's use em
      # and call it a day!
      log_with_time "  - checking cache for built pkg" if @verbose
      if b.install_from_cache
        log_with_time "      Installed from cache!  all done." if @verbose
        next
      # if use_source is specified for this package it short circuts
      # fetch and unpack
      elsif @use_source && @use_source.has_key?(p)
        log_with_time "  - copying local source for #{p} (#{@use_source[p]})" if @verbose      
        b.use_source @use_source[p]
      else 
        log_with_time "  - fetching #{p}" if @verbose      
        b.fetch
        log_with_time "  - unpacking #{p}" if @verbose      
        b.unpack
      end
      log_with_time "  - patching #{p}" if @verbose      
      b.patch
      log_with_time "  - post-patch #{p}" if @verbose      
      b.post_patch
      @build_types.each { |bt|
        log_with_time "  - pre_build step for #{p} (#{bt})" if @verbose      
        b.pre_build bt
        log_with_time "  - configuring #{p} (#{bt})" if @verbose      
        b.configure
        log_with_time "  - building #{p} (#{bt})" if @verbose      
        b.build
        log_with_time "  - installing #{p} (#{bt})" if @verbose      
        b.install
        log_with_time "  - running post_install for #{p} (#{bt})" if @verbose      
        b.post_install
      }
      log_with_time "  - running post_install_common for #{p}" if @verbose      
      b.post_install_common
      log_with_time "  - cleaning up #{p}" if @verbose      
      b.dist_clean
      log_with_time "  - Writing receipt for #{p}" if @verbose      
      b.write_receipt
      log_with_time "  - Saving #{p} build output to cache (#{@cache_dir})" if @verbose      
      b.save_to_cache
    }
  end
end
