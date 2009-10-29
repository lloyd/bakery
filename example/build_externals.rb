#!/usr/bin/env ruby

require "../ports/bakery"
require 'pp'

$order = {
  :output_dir => File.join(File.dirname(__FILE__), "ext"),
  :packages => [ "yajl" ],
  :verbose => true
}

b = Bakery.new $order
b.build

