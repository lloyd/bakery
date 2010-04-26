$first_log_msg = nil 

def log_get_time
  $first_log_msg = Time.now if $first_log_msg == nil 
  sprintf("(%.1f)", Time.now - $first_log_msg)
end

def log_with_time msg
  puts "#{log_get_time} #{msg}"
end

