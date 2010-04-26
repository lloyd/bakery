def __fastMD5 file
  d = Digest::MD5.new
  chunk = nil
  md5 = nil
  begin
    File.open(file, "rb") { |f|
      while (chunk = f.sysread(4096))
        d.update(chunk)
      end
    }
  rescue EOFError
    d.to_s
  end
end
