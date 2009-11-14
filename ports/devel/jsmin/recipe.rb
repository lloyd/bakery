{
  :url => nil,
  :md5 => nil,
  :build => lambda { |c|
    # compile jsmin.c 
    puts c[:source_dir]
    jsminSrc = File.join(c[:recipe_dir], "jsmin.c")
    if c[:platform] == :Windows
      raise "not yet implemented!  gotta compile! XXX"
    else
      cmd = "gcc -Wall -g -o jsmin #{jsminSrc}"
      puts "CC: #{cmd}"
      system(cmd)
    end
  },
  :install => lambda { |c|
    FileUtils.cp("jsmin", c[:output_bin_dir],
                 { :verbose => true, :preserve => true })
  }
}
