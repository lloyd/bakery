{
  :url => {
    :Windows => 'http://github.com/downloads/browserplus/platform/bpsdk_2.10.0-Win32-i386.zip',
    :MacOSX => 'http://github.com/downloads/browserplus/platform/bpsdk_2.10.0-Darwin-i386.tgz',
    :Linux => 'http://github.com/downloads/browserplus/platform/bpsdk_2.10.0-Linux-x86_64.tgz'
  },
  :md5 => {
    :Windows => '2c7a8dab73a3ba8ef4c29d4c047b687e',
    :MacOSX => '99347978175a84ba959b7d1199f5c2d7',
    :Linux => '5eb008563b8ea5d8c22921fb0c3a1476'
  },
  :install => lambda { |c|
    ext = (c[:platform] == :Windows ? ".exe" : "")
    FileUtils.cp(File.join(c[:src_dir], "bin", "ServiceRunner#{ext}"),
                 c[:output_bin_dir],
                 { :verbose => true, :preserve => true })
  }
}
