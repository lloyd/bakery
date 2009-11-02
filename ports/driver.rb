#!/usr/bin/env ruby
# 
# a command line driver for the bakery, most useful for
# recipe authors
#

require File.join(File.dirname(__FILE__), 'bakery')

if ARGV.length < 1
  puts "usage: driver.rb <command> [arguments]"
  puts "commands: "
  puts "   build <portname>   -- build a specific port"
  puts "   list               -- list all ports"
  exit 1
end

case ARGV[0]
when 'build'
  if ARGV.length < 2
    puts "usage: driver.rb build <port name>"
    exit 1
  end
  myorder = { :packages => [ ARGV[1] ], :verbose => true }
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
  STDERR.puts "unrecognized command: #{ARGV[1]}"
  exit 1
end

