#!/usr/bin/ruby
require 'rubygems'
require 'data_mapper'
require 'dm-mysql-adapter'
DataMapper.setup(:default, {
 :adapter => 'mysql',
 :host => 'localhost',
 :username => 'tw981' ,
 :password => 'thaetsbb',
 :database => 'tw981'})

class Caller
  include DataMapper::Resource

  property :id, Serial # An auto-increment integer key
  property :caller_id, String # A varchar type string, for short strings
  property :created_at, DateTime # A DateTime, for any date you might like.
end

# Automatically create the tables if they don't exist
#DataMapper.auto_upgrade!
# Finish setup
DataMapper.finalize
DataMapper.auto_upgrade!
new_call=Caller.create(:caller_id => "17187531176", :created_at => Time.now)
new_call.save()
