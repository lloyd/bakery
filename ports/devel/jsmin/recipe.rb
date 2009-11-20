{
  :build => lambda { |c|
    # compile jsmin.c 
    puts c[:source_dir]
    jsminSrc = File.join(c[:recipe_dir], "jsmin.c")
    if c[:platform] == :Windows
      cmd = "cl #{jsminSrc}"
      system(cmd)
    else
      cmd = "gcc -Wall -g -o jsmin #{jsminSrc}"
      system(cmd)
    end
  },
  :install => lambda { |c|
    ext = (c[:platform] == :Windows) ? ".exe" : ""
    FileUtils.cp("jsmin#{ext}", c[:output_bin_dir],
                 { :verbose => true, :preserve => true })
  }
}
