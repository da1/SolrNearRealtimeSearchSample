#!/usr/bin/env ruby
require 'rubygems'
require 'sinatra'
require 'haml'
require 'mongoid'
require 'rsolr'

require 'sinatra/reloader'

Mongoid.configure do |conf|
    conf.connect_to('sample')
end

class Tweet
    include Mongoid::Document
    field :tweet
    field :created_at, :type => DateTime, :default => lambda{Time.now}
end

url = 'http://localhost:8983/solr'
solr = RSolr.connect :url => url

get '/' do
    @title = "sample"
    @tweets = Tweet.all().reverse;
    haml :index
end

post '/add' do
    tw = params[:tweet]
    time = Time.now
    post_time = time.strftime("%Y-%m-%dT%H:%M:%SZ")

    solr.add :id => time.to_i, :tweet_ss => tw, :time_dts => post_time
    Tweet.create({
        :tweet      => tw,
        :created_at => post_time
    })
    redirect '/'
end

get '/search' do
    @title = "tweet search"
    query = params[:search]
    params = {:q => "tweet_ss:" + query, :wt => :ruby}
    response = solr.get 'select', :params => params
    @length = response["response"]["docs"].length
    @result = response["response"]["docs"]
    haml :search
end
