{
  :deps => [ "service_runner" ], 
  :url => 'github://browserplus/service-testing/df7d6c6f0b00d4fbd6f7e3791b252da94f55ca42',
  :install => lambda { |c|
    tgtDir = File.join(c[:output_dir], "share", "service_testing")
    FileUtils.mkdir_p(tgtDir)
    FileUtils.cp(File.join(c[:src_dir], "ruby", "bp_service_runner.rb"),
                 tgtDir,
                 { :verbose => true, :preserve => true })
  }
}
