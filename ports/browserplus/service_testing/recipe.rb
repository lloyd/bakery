{
  :deps => [ "service_runner" ], 
  :url => 'github://browserplus/service-testing/0b95af1f4cf91075923a5e45742bc469a0521d66',
  :install => lambda { |c|
    tgtDir = File.join(c[:output_dir], "share", "service_testing")
    FileUtils.mkdir_p(tgtDir)
    FileUtils.cp(File.join(c[:src_dir], "ruby", "bp_service_runner.rb"),
                 tgtDir,
                 { :verbose => true, :preserve => true })
  }
}
