#!/usr/bin/ruby -w
# frozen_string_literal: true

#
# Remove PII for GDPR users in the system using the <filename.csv>
# only run in heroku to execute in prod
# use analytics to test
#
# To create csv file in heroku, run this command:
# ~ $ echo 'emails
# > test1@gmail.com
# > test2@gmail.com
# > test3@gmail.com' > gdpr_users.csv
#
# usage: bundle exec ruby bin/gdpr.rb <filename.csv>
#
# param 1  : the file name of the csv. CSV must be in the form:
#  email
#  some1@email.com
#  some2@email.com
#
#

require 'logger'
require 'http'
require 'optparse'
require 'uri'


@logger = Logger.new(STDOUT)
@error = Logger.new(STDERR)
@username = ENV['USERNAME']
@client_id = ENV['CLIENT_ID']


@options = {}
OptionParser.new do |opts|
  opts.on("-v", "--verbose", "Show extra information") do
    @options[:verbose] = true
  end
  opts.on("-c", "--color", "Enable syntax highlighting") do
    @options[:syntax_highlighting] = true
  end
  opts.on("-l", "--login", "Login") do
    @options[:login] = true
  end
  opts.on("-s", "--store", "Store a token") do
    @options[:store] = true
  end
  opts.on("-t", "--list", "List tokens") do
    @options[:list_token] = true
  end
end.parse!
#p @options


def post_login
    begin

        ssl_context = OpenSSL::SSL::SSLContext.new
        ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
        http = HTTP #basic_auth(:user => 'apiclient', :pass => ENV['SPLUNK_TOKEN'])
        unless ENV['QUOTAGUARDSTATIC_URL'].nil?
          uri = URI.parse(ENV['QUOTAGUARDSTATIC_URL'])
          host = uri.hostname
          user = uri.user
          password = uri.password
          port = uri.port
          http = http.via(host, port, user, password)
        end

        response = http.post(
            "https://github.com/login/device/code",
            :form => {:client_id => @client_id,:scope => "repo"}#"admin:gpg_key"}
        )

        json = URI.decode_www_form(response.body.to_s)
        p json[3][1]
        p json
        # figure out how to submit this open with the user_code in the response body
        system "open https://github.com/login/device"
        $stdin.gets.chomp
        return json[0][1]
    rescue StandardError => e

        @error.fatal(e.message)
        @error.fatal(e.backtrace)
        @error.fatal('ERROR unable to login to github')
        exit(1)
    
    ensure
        #http&.close()
    end
end



def post_get_access_token(device_code)
    begin

        ssl_context = OpenSSL::SSL::SSLContext.new
        ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
        http = HTTP #basic_auth(:user => 'apiclient', :pass => ENV['SPLUNK_TOKEN'])
        unless ENV['QUOTAGUARDSTATIC_URL'].nil?
          uri = URI.parse(ENV['QUOTAGUARDSTATIC_URL'])
          host = uri.hostname
          user = uri.user
          password = uri.password
          port = uri.port
          http = http.via(host, port, user, password)
        end

        response = http.post(
            "https://github.com/login/oauth/access_token",
            :form => {:client_id => @client_id,
                      :device_code => device_code,
                      :grant_type => "urn:ietf:params:oauth:grant-type:device_code"}
        )

        json = URI.decode_www_form(response.body.to_s)
        p json
        return json[0][1]
    rescue StandardError => e

        @error.fatal(e.message)
        @error.fatal(e.backtrace)
        @error.fatal('ERROR unable to login to github')
        exit(1)
    
    ensure
        #http&.close()
    end
end


def store_creds(access_code)
    #system "echo \"\nprotocol=https\nhost=github.com\n\""
    #system "git credential-osxkeychain erase\nprotocol=https\nhost=github.com\n\""
    system "echo \"\\\n"\
            "protocol=https\n"\
            "host=github.com\" | git credential-osxkeychain erase\n"
    sleep(1)
    system "echo \"\\\n"\
            "protocol=https\n"\
            "host=github.com\n"\
            "username=#{@username}\n"\
            "password=#{access_code}\" | git credential-osxkeychain store\n"
end


if @options[:login] == true
    store_creds(post_get_access_token(post_login))
elsif @options[:store] == true
    store_creds("1234")
end
