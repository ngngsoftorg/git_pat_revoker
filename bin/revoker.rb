#!/usr/bin/ruby -w
# frozen_string_literal: true

#
# List or revoke personal access tokens for the SAML SSO org specified
#
# To list tokens, run this command:
# > bundle exec bin/revoker.rb -l forgeglobal
#
# To revoke tokens, run this command:
# > bundle exec bin/revoker.rb -r forgeglobal
#
# To revoke a specific user's token, run this command:
# > bundle exec bin/revoker.rb -r forgeglobal ngrabowski
#
# Usage: revoker.rb [options]
#   -v, --verbose                    Show extra information
#   -h, --help                       Show this message
#   -r, --revoke ORG                 Revokes all SAML SSO tokens for users in a given org
#   -n, --name NAME                  Revokes SAML SSO token for named user in a given org
#   -l, --list ORG                   List all SAML SSO tokens for users in a given org
#
#

require 'logger'
require 'http'
require 'optparse'
require 'uri'


@logger = Logger.new(STDOUT)
@error = Logger.new(STDERR)
# use one of the bot account PATs


@options = {}
@org = ""
OptionParser.new do |opts|
  opts.banner = "Usage: bundle exec bin/revoker.rb [options]"
  opts.on("-v", "--verbose", "Show extra information") do
    @options[:verbose] = true
  end
  opts.on("-h", "--help", "Show this message") do
    puts opts
    exit
  end
  opts.on("-r ORG", "--revoke ORG", "Revokes all SAML SSO tokens for users in a given org") do |org|
    @org = org
    @options[:revoke] = true
  end
  opts.on("-n NAME", "--name NAME", "Revokes SAML SSO token for named user in a given org") do |name|
    unless @options[:revoke] == true
        puts opts
        exit(1)
    end
    @name = name
    @options[:name] = true
  end
  opts.on("-l ORG", "--list ORG", "List all SAML SSO tokens for users in a given org") do |org|
    @org = org
    @options[:list_token] = true
  end
end.parse!

def get_list_tokens

    begin
        ssl_context = OpenSSL::SSL::SSLContext.new
        ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
        http = HTTP
        if @options[:verbose] == true
            http = HTTP.use(logging: {logger: @logger})
        end 
        
        response = http.auth("token #{@token}")
            .headers(:accept => "application/vnd.github.v3+json")
            .get("https://api.github.com/orgs/#{@org}/credential-authorizations"
        )

        if response.status != 200 
            raise StandardError.new("#{response.status} \n #{response}")
        end

        result = []
        hash = response.parse
        hash.each do |h|
            @logger.info(h["login"] + " " + h["credential_id"].to_s + " " + h["authorized_credential_note"].to_s) if @options[:verbose] == true
            result.push({"login"=>h["login"],"credential_id"=>h["credential_id"].to_s})
        end

        return result
    rescue StandardError => e

        @error.fatal(e.message)
        @error.fatal(e.backtrace)
        @error.fatal('ERROR unable to list SAML SSO tokens in github')
        exit(1)
    
    ensure
    end
end

def revoke_token(cred_id)
    begin

        ssl_context = OpenSSL::SSL::SSLContext.new
        ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
        http = HTTP
        if @options[:verbose] == true
            http = HTTP.use(logging: {logger: @logger})
        end

        response = http.auth("token #{@token}")
            .headers(:accept => "application/vnd.github.v3+json")
            .delete("https://api.github.com/orgs/#{@org}/credential-authorizations/#{cred_id}"#,
        )

        if response.status != 204 
            raise StandardError.new("#{response.status} \n #{response}")
        end
    rescue StandardError => e

        @error.fatal(e.message)
        @error.fatal(e.backtrace)
        @error.fatal('ERROR unable to revoke authorization for SAML SSO tokens in github')
        exit(1)
    
    ensure
    end
end


unless ENV['GITHUB_ACCESS_TOKEN']
    puts 'Environment variable GITHUB_ACCESS_TOKEN missing'
    exit(1)
end
@token = ENV['GITHUB_ACCESS_TOKEN']

if @options[:revoke] == true
    tokens = get_list_tokens
    tokens.each do |token|
        p "removing token " + token["login"] + " " + token["credential_id"].to_s
        #revoke_token(token["credential_id"]) if token["login"] == @name
    end
elsif @options[:list_token] == true
    tokens = get_list_tokens
    tokens.each do |token|
        p token["login"] + " " + token["credential_id"].to_s 
    end
end

@logger.info(@options) if @options[:verbose] == true
@logger.info(@org) if @options[:verbose] == true

# Oauth-applications-api
# revoke a bearer token for an OAuth app... 
# ... looks like this is done by the one who installed the app... so could be done right after 
# pat is created
# https://docs.github.com/en/rest/reference/apps#oauth-applications-api
#
#
# THis one let's an admin delete an authorixzation for a user
# https://docs.github.com/en/rest/reference/orgs#remove-a-saml-sso-authorization-for-an-organization
