{
  :deps => [ "service_runner" ], 
  :url => 'github://browserplus/service-testing/154e5448716f546cda58a3577e0bedcf660b20b2',
  :install => lambda { |c|
    tgtDir = File.join(c[:output_dir], "share", "service_testing")
    FileUtils.mkdir_p(tgtDir)
    FileUtils.cp(File.join(c[:src_dir], "ruby", "bp_service_runner.rb"),
                 tgtDir,
                 { :verbose => true, :preserve => true })
    FileUtils.cp(File.join(c[:src_dir], "ruby", "cppunit_runner.rb"),
                 tgtDir,
                 { :verbose => true, :preserve => true })
    FileUtils.cp_r(File.join(c[:src_dir], "ruby", "json"),
                   tgtDir,
                   { :verbose => true, :preserve => true })
  }
}
