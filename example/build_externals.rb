#!/usr/bin/env ruby

require "../bakery"

$order = {
  :output_dir => File.join(File.dirname(__FILE__), "ext"),
  :software => [
    { :name => "yajl", :version => "1.0.7" }
  ]
}

b = Bakery.new $order
b.build
