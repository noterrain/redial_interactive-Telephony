#!/usr/bin/ruby

call_id=ARGV[0]
time=Time.now.to_s
log_file="/home/ck987/call_log.txt"
# 'a' = append text
file = File.open(log_file, 'a')
file.write("Call from #{call_id} received at #{time}\n")
file.close

