{
  :deps => [ "service_runner" ], 
  :url => 'http://github.com/downloads/browserplus/service-testing/0.0.1.tgz',
  :md5 => '410a56a2802927b28cc3e84961f43532',
  :install => lambda { |c|
    tgtDir = File.join(c[:output_dir], "share", "service_testing")
    FileUtils.mkdir_p(tgtDir)
    FileUtils.cp(File.join(c[:src_dir], "ruby", "bp_service_runner.rb"),
                 tgtDir,
                 { :verbose => true, :preserve => true })
  }
}
