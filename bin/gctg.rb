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


@logger = Logger.new(STDOUT)
@error = Logger.new(STDERR)



@options = {}
OptionParser.new do |opts|
  opts.on("-v", "--verbose", "Show extra information") do
    @options[:verbose] = true
  end
  opts.on("-c", "--color", "Enable syntax highlighting") do
    @options[:syntax_highlighting] = true
  end
end.parse!
p @options


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
            :form => {:client_id => "626b7def390fced9ac7c",:scope => "admin:gpg_key"}
        )

        p response.body.to_s
    
    rescue StandardError => e

        @error.fatal(e.message)
        @error.fatal(e.backtrace)
        @error.fatal('ERROR unable to login to github')
        exit(1)
    
    ensure
        #http&.close()
    end
end



def post_get_access_token
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
            :form => {:client_id => "626b7def390fced9ac7c",
                      :device_code => "04f3b0e270bffb806a174e8ae138eb187e90cf01",
                      :grant_type => "urn:ietf:params:oauth:grant-type:device_code"}
        )

        p response.body.to_s
    
    rescue StandardError => e

        @error.fatal(e.message)
        @error.fatal(e.backtrace)
        @error.fatal('ERROR unable to login to github')
        exit(1)
    
    ensure
        #http&.close()
    end
end

#post_login
post_get_access_token

def remove_users

  # load the emails from a file
  arr_of_rows = CSV.read(ARGV[0], headers: true)

  @logger.info("read emails from file #{ARGV[0]}")
  result = 0

  arr_of_rows.each do |row|
    unless (URI::MailTo::EMAIL_REGEXP =~ row[0]) == nil then
      result = result + remove(row)
    else
      @logger.info("invlaid email #{row[0]} ... skipping")
    end
  end

  @logger.info("gdpr'd #{result.to_s} accounts")
end


def remove(row)

  @logger.info("gdpr account #{row[0]}")
  current_email = row[0]

  random = rand(10000000)
  new_email = Time.now.strftime("%Y-%m-%d") + "-#{random.to_s}@gdpr_delete_request.com"
  result = 0

  #http = HTTP #.use(logging: {logger: logger})  
  uri = URI.parse(ENV['SHAREX_DATABASE_URL'])
  host = uri.hostname
  user = uri.user
  password = uri.password
  port = uri.port
  db = uri.path[1..-1]
  con = nil

  begin
    con = PG.connect host: host, port: port, dbname: db, user: user, password: password

    raise 'ERROR could not open con' unless con

    # run the job for buyers
    rs = con.exec("update accounts set email='#{new_email}', phone='555-555-5555'," \
            "zip_code=null,first_name='gdpr',last_name='gdpr'," \
            "active_us_address=null,last_login_from_ip_address=null," \
            "government_id_id=null where lower(email) = lower('#{current_email}');")

    if rs.cmd_tuples < 1 then
      @logger.info("No account was gdpr'd: #{rs.inspect.to_s}")
    else
      @logger.info("Result : #{rs.cmd_tuples.to_s} account gdpr'd")
      result = 1
    end

  rescue StandardError => e
    @logger.fatal(e.message)
    @logger.fatal(e.backtrace)
    @logger.fatal('ERROR unable to remove gdpr account')
    exit(1)
  ensure
    unless con == nil
      con&.close
    end
  end

  return result
end


