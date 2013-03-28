#!/usr/bin/ruby
require 'rubygems'
require 'ruby-agi'
require 'fileutils'
require 'net/http'		#for http connections
require 'rexml/document'	#for parsing XML
# Get Arguments

weatherURL = []
weatherURL << "http://asterisk.itp-redial.com/~tw981/sinatra/main_agi/xml" #NYC

url = weatherURL[0]
# get the XML data as a string
	xml_data = Net::HTTP.get_response(URI.parse(url)).body
	# extract event information
	doc = REXML::Document.new(xml_data)
	temp_f = doc.get_text('blog_post/timec')

current_f=temp_f
phone_number_to_call = ARGV[0]
hours = current_f.value.to_i

hour_in_seconds = 60
day_in_seconds = hour_in_seconds*24
default_hour = 21 #9pm
#year [, month, day, hour, min, sec, usec]
time_to_call = Time.now
if hours > 0
	hour = Time.now.hour+hours
	if hour > 29
			#call the next day at default hour
		time_to_call = Time.local(Time.now.year,Time.now.month,Time.now.day,default_hour,0,0)
		time_to_call = time_to_call + day_in_seconds #roll forward 1 day
	else
		time_to_call = time_to_call + (hour_in_seconds *hours)
	end
else
	#call the next day at default hour
	time_to_call = Time.local(Time.now.year,Time.now.month,Time.now.day,default_hour,0,0)
	time_to_call = time_to_call + day_in_seconds #roll forward 1 day
end

temp_dir = "/tmp/"
callfile = "call_#{time_to_call.to_i}.call"
startcallfile = temp_dir + callfile
end_dir = "/var/spool/asterisk/outgoing/"
endcallfile = end_dir + callfile
#write file to disk
file = File.open(startcallfile,"w")
file.puts("Channel: SIP/#{phone_number_to_call}@flowroute\n")
file.puts("MaxRetries: 2\n")
file.puts("RetryTime: 30\n")
file.puts("WaitTime: 60\n")
file.puts("Context: tw981_stock\n")
file.puts("Extension: s\n")
file.puts("CallerID: Kairalla <17187531176>\n")
file.close
#change file permission
File.chmod(0777, startcallfile)
FileUtils.chown(ENV['USER'],'asterisk',startcallfile)
File.utime(time_to_call,time_to_call,startcallfile) #change file time to future date
#move file to /var/spool/asterisk/outgoing
FileUtils.mv(startcallfile,endcallfile)