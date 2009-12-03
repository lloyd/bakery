#!/usr/bin/env ruby
# 
# a command line driver for the bakery, most useful for
# recipe authors
#

require File.join(File.dirname(__FILE__), 'bakery')
require 'pp'

if ARGV.length < 1
  puts "usage: driver.rb <command> [arguments]"
  puts "commands: "
  puts "   build <portname>   -- build a specific port"
  puts "      [ --use_source=<path> ] -- optional path to local source.  "
  puts "                               (tarball or directory)"
  puts "   list               -- list all ports"
  exit 1
end

# simple argument parsing
myargv = Array.new
cl_args = Hash.new
ARGV.each { |a|
  if m = a.match(/^--(.*)=(.*)/)
    cl_args[m[1]] = m[2]
  else
    myargv.push a
  end
}

case myargv[0]
when 'build'
  if myargv.length != 2
    puts "usage: driver.rb build <port name>"
    exit 1
  end
  myorder = { :packages => [ myargv[1] ], :verbose => true }
  if cl_args.has_key? "use_source"
    myorder[:use_source] = { myargv[1] => cl_args["use_source"] } 
  end
  if cl_args.has_key? "use_recipe"
    myorder[:use_recipe] = { myargv[1] => cl_args["use_recipe"] } 
  end
  puts "synthesized order: "
  pp myorder
  b = Bakery.new(myorder) 
  b.build
when 'list'
  allPorts = Array.new
  Dir.chdir(File.dirname(__FILE__)) {
    Dir.glob(File.join("**", "recipe.rb")).each { |p| 
      allPorts.push(File.dirname(p))
    }                                                  
  }                                                  
  puts "#{allPorts.length} ports available:"
  allPorts.sort.each { |p| puts "  #{p}" }
else
  STDERR.puts "unrecognized command: #{myargv[1]}"
  exit 1
end

