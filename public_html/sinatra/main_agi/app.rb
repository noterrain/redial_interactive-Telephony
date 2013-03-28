#!/usr/bin/ruby
require 'sinatra'
require 'rubygems'
require 'data_mapper'
require 'fileutils'

DataMapper::setup(:default, {:adapter => 'yaml', :path => 'db'})

#DataMapper.setup(:default, {
# :adapter  => 'mysql',
# :host     => 'localhost',
# :username => 'tw981' ,
# :password => 'thaetsbb',
# :database => 'tw981'})

class BlogPost
  include DataMapper::Resource
  property :id, Serial
  property :timec, Text
end

DataMapper.finalize

get "/" do
  erb :open
end

post "/save" do
  
  myPost = BlogPost.new
  myPost.timec = params[:Time]
  
  if(myPost.save)
    @message = "Your post was saved!"
  else
    @message = "Your post was NOT SAVED!!!!!!!"
  end
  
  erb :save
  #"hello world"
end

get "/hello" do
  @posts = BlogPost.all
  erb :hello
end

get '/xml' do
  @last_post = BlogPost.last
  @last_post.to_xml
end
