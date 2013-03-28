#!/usr/bin/ruby

require 'rubygems'
require 'ruby-agi'		#for Asterisk AGI
require 'net/http'		#for http connections
require 'rexml/document'	#for parsing XML

agi = AGI.new

# for a complete list of US cities, go to
# http://www.weather.gov/xml/current_obs/
weatherURL = []
weatherURL << "http://w1.weather.gov/xml/current_obs/KNYC.xml" #NYC
weatherURL << "http://feeds.finance.yahoo.com/rss/2.0/headline?s=intc&region=US&lang=en-US" 

#while true #loop forever

	url = weatherURL[0]
	# get the XML data as a string
	xml_data = Net::HTTP.get_response(URI.parse(url)).body
	# extract event information
	doc = REXML::Document.new(xml_data)
	temp_f = doc.get_text('current_observation/temp_f')
	stock = doc.get_text('current_observation/pressure_in')

	if temp_f
		current_temp = temp_f
	else
		agi.noop("couldn't find temp in xml. quitting.")
		continue = false
		exit #quit ruby
	end
	
	if stock
		current_stock = stock
	else
		agi.noop("couldn't find temp in xml. quitting.")
		continue = false
		exit #quit ruby
	end
	#say the temp and ask for another digit
	agi.stream_file("/home/tw981/asterisk_sounds/midterm/opening")
	agi.stream_file("/home/tw981/asterisk_sounds/midterm/temperature")
	agi.say_number(current_temp)
	agi.stream_file("/home/tw981/asterisk_sounds/midterm/stock")
	agi.say_number(current_stock)
	agi.stream_file("/home/tw981/asterisk_sounds/midterm/pills")
	agi.stream_file("/home/tw981/asterisk_sounds/midterm/sleep")
#end
