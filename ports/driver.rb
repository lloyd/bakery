#!/usr/bin/env ruby
# 
# a command line driver for the bakery, most useful for
# recipe authors
#

require File.join(File.dirname(__FILE__), 'bakery')

if ARGV.length < 1
  puts "usage: driver.rb <command> [arguments]"
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
else
  STDERR.puts "unrecognized command: #{ARGV[1]}"
  exit 1
end

