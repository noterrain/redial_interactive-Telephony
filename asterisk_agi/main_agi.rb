#!/usr/bin/ruby

require 'rubygems'
require 'ruby-agi'		#for Asterisk AGI
require 'net/http'		#for http connections
require 'data_mapper'   #for mysql database integration
require '/var/lib/asterisk/agi-bin/mailer.rb' #for sending email

#caller ID setup function.  Add a 1 to local usa numbers if needed.
def validate_caller_id(call_id)
	first_digit = call_id.split('')[0];
	#check to see if we need to add a 1
	if (first_digit != '1' && call_id.length == 10)
		call_id = "1" + call_id
	end
	return call_id
end

# some variables for later use
#welcome_back_audio = "/home/ck987/asterisk_sounds/welcome_back"
#greetings_we_have_never_met_audio = "/home/ck987/asterisk_sounds/greetings_we_have_never_met"
#please_record_your_name_audio = "/home/ck987/asterisk_sounds/please_record_your_name"
#where_would_you_like_to_go_audio = "/home/ck987/asterisk_sounds/where_would_you_like_to_go"
names_location = "/home/tw981/public_html/redial/names/"

#Create an AGI Object
agi = AGI.new
DataMapper::Model.raise_on_save_failure = true
#set up database
DataMapper.setup(:default, {
 :adapter  => 'mysql',
 :host     => 'localhost',
 :username => 'tw981' ,
 :password => 'thaetsbb',
 :database => 'tw981'})
 #caller model for database interaction
 class Caller
  include DataMapper::Resource

  property :id, 		Serial
  property :caller_id, 	String, :required => true
  property :name_audio, String, :required => true, :length => 64
  property :last_call_time, DateTime
  property :created_at, DateTime
end
# Automatically create the tables if they don't exist
DataMapper.auto_upgrade!
# Finish setup
DataMapper.finalize

#set caller ID
callerID = validate_caller_id(agi.callerid)
#Query the database to see if this caller has called before.
#Pick the last record in the database that matches call id(the most recent call)
caller = Caller.last(:caller_id => callerID)

if caller
	#We got a result from the database, play welcome message
	agi.stream_file(welcome_back_audio)
	#pause 1 second to let stream file bug pass
	sleep(1)
	agi.stream_file(caller.name_audio)
	# wait_for_digits is similar to the Dialplan command Background
	#it plays the audio file, has a timeout in milliseconds and a max number of digits to receive.
	#wait_for_digits actually calls AGI command "GET DATA" and I really wish they'd just called it get_data to avoid confusion.
	whereto = agi.wait_for_digits(where_would_you_like_to_go_audio, 10000, 1)

	#whereto.digits is the digits that are pressed
	#send them to the console for debugging
	#say them for debugging
	if (whereto.digits)
		agi.noop("Result: " + whereto.digits)
		agi.say_number(whereto.digits)
		#execute the Goto Dialplan command
		agi.exec('Goto',"tw981,#{whereto.digits},1")
	else
		#Timeout.. Probably
		agi.exec('Goto','tw981,t,1')
	end
else
	#We don't know this person, let's get them to record their name
	agi.stream_file(greetings_we_have_never_met_audio)
	#pause 1 second to let stream file bug pass
	sleep(1)
	agi.stream_file(please_record_your_name_audio)
	record_file = names_location + "name_" +callerID
	agi.record_file(record_file, "WAV", "0123456789#*", 10000, true);
	#Insert this into the database
	new_call=Caller.create(	:caller_id => callerID,
							:name_audio => record_file,
							:last_call_time => Time.now,
							:created_at => Time.now)
	success = new_call.save()
	whereto = agi.wait_for_digits(where_would_you_like_to_go_audio, 10000, 1)
	if (whereto.digits)
		agi.noop("Result: " + whereto.digits)
		agi.say_number(whereto.digits)

		subject = "New Caller: " + callerID
		body = "#{callerID} has recorded their name.  Check the attachment or visit this page: http://itp.nyu.edu/~tw981/sinatra/main_agi/names?file=name_#{callerID}\n"
		mailer = Mailer.new
		mailer.mail_attachment("tw981@nyu.edu",subject,body,record_file + ".WAV")
		#execute the Goto Dialplan command
		agi.exec('Goto',"tw981,#{whereto.digits},1")
	else
		#Timeout.. Probably
		agi.exec('Goto','tw981,t,1')
	end
end