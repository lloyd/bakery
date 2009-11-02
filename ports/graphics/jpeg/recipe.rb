{
  :url => "http://quirkysoft.googlecode.com/files/jpegsrc.v6b.tar.gz",
  :md5 => "dbd5f3b47ed13132f04c685d608a7547",
  :configure => {
    [ :Linux, :MacOSX ] => lambda { |c|
      ENV['CFLAGS'] = "#{c[:os_compile_flags]} #{ENV['CFLAGS']}"
      ENV['CFLAGS'] += ' -g -O0 ' if c[:build_type] == :debug
      ENV['LDFLAGS'] = "#{c[:os_link_flags]} #{ENV['LDFLAGS']}"
      cfgScript = File.join(c[:src_dir], "configure")
      cfgOpts = "--enable-static --disable-shared --prefix=\"#{c[:output_dir]}\""
      puts "#{cfgScript} #{cfgOpts}"
      system("#{cfgScript} #{cfgOpts}")
    }    
  },
  :build => {
    [ :Linux, :MacOSX ] => "make"
  },
  :install => {
    [ :Linux, :MacOSX ] => "make install"
  }
}
