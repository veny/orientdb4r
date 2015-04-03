require 'rake/testtask'
require 'rest_client'

Rake::TestTask.new do |t|
  t.libs = ['lib', 'test']
  t.pattern = 'test/**/test_*.rb'
end

desc "Run tests"
task :default => :test

namespace :db do

  DB_HOST = 'localhost'
  DB_PORT = 2480
  DB_NAME = 'temp'
  DB_ROOT_USER = 'root'
  DB_ROOT_PASS = ENV['ORIENTDB_ROOT_PASS'] || 'root'

  desc 'Check whether a test DB exists and create if not'
  task :setup4test do
    found = true
    begin
      ::RestClient::Request.new({:url=>"http://#{DB_HOST}:#{DB_PORT}/database/#{DB_NAME}", :method=>:get, :user=>DB_ROOT_USER, :password=>DB_ROOT_PASS}).execute
    rescue Errno::ECONNREFUSED
      fail "server seems to be closed, not running on #{DB_HOST}:#{DB_PORT}?"
    rescue ::RestClient::Unauthorized
      # this is expected reaction if DB does not exist
      puts 'DB does NOT exist -> create'
      found = false
    rescue ::RestClient::Exception => e
      fail "unexpected failure: #{e}"
    end

    if found
      puts 'DB already exists'
    else
      ::RestClient::Request.new({:url=>"http://#{DB_HOST}:#{DB_PORT}/database/#{DB_NAME}/memory", :method=>:post, :user=>DB_ROOT_USER, :password=>DB_ROOT_PASS}).execute
      puts 'DB created'
    end
  end

end
