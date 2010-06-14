{
  :deps => [ "service_runner" ], 
  :url => 'github://browserplus/service-testing/d4f5da714f4b0618925624dd541492216b9298ef',
  :install => lambda { |c|
    tgtDir = File.join(c[:output_dir], "share", "service_testing")
    FileUtils.mkdir_p(tgtDir)
    FileUtils.cp(File.join(c[:src_dir], "ruby", "bp_service_runner.rb"),
                 tgtDir,
                 { :verbose => true, :preserve => true })
  }
}
