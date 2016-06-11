# The MIT License (MIT)
# Copyright (c) 2016 Davide Petilli
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom
# the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
# OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# Module hosting Zoho communication methods
module ZohoTalker
  @interface = {
    get_contacts: 'https://crm.zoho.com/crm/private/json/Contacts/getRecords',
    get_token: 'https://accounts.zoho.com/apiauthtoken/nb/create'
  }

  # The ZohoCRM API limits max requests to 200,
  # so we get records 200 at a time
  @from_index = 1
  @to_index = 200

  @credentials = { username: nil, password: nil }

  class << self
    def obtain_new_token
      puts 'Can\'t find a valid ZohoCRM authtoken. Obtaining new one.'
      begin
        ask_for_token
      rescue Interrupt
        puts "\nExiting..."
        exit
      end
    end

    def ask_for_data(zoho_token)
      params = {
        newFormat: 2, authtoken: zoho_token, scope: 'crmapi',
        fromIndex: @from_index, toIndex: @to_index,
        selectColumns: 'Contacts(Lead Source,First Name,Last Name,Email,Mobile)'
      }
      response = Response.new(@interface[:get_contacts], params)
      increment_indexes
      response.body
    end

    private

    def increment_indexes
      @from_index += 200
      @to_index += 200
    end

    def new_username
      # TODO: Add some control for the input
      print 'Enter ZohoCRM username: '
      @credentials[:username] = gets.chomp
    end

    def new_password
      print 'Enter ZohoCRM password: '
      @credentials[:password] = gets.chomp
    end

    def new_credentials
      new_username
      new_password
    end

    def ask_for_token
      loop do
        new_credentials
        params = {
          SCOPE: 'ZohoCRM/crmapi', DISPLAY_NAME: 'Ztos',
          EMAIL_ID: @credentials[:username], PASSWORD: @credentials[:password]
        }
        response = Response.new(@interface[:get_token], params)
        response = response.parse_token_response
        response.without_errors? ? response[1] : next
      end
    end
  end

  # A class that handles and validates the response received from ZohoCRM
  class Response
    ERROR_RESPONSES = %w(INVALID_PASSWORD
                         NO_SUCH_USER
                         EXCEEDED_MAXIMUM_ALLOWED_AUTHTOKENS).freeze

    def initialize(uri, params)
      @response = response_from_uri(uri, params)
    end

    def parse_token_response
      @response.body.split($RS)[2].split('=') if @response
    end

    def without_errors?
      unless (@response & ERROR_RESPONSES).empty?
        message = @response[1].split('_').map do |word|
          word.downcase.capitalize
        end
        puts 'ERROR: ' + message.join(' ')
      end
      true
    end

    def body
      @response.body
    end

    private

    def response_from_uri(uri, params)
      uri = URI(uri)
      uri.query = URI.encode_www_form(params)
      @response = Net::HTTP.get_response(uri)
      @response.is_a?(Net::HTTPSuccess) ? @response : nil
    end
  end
end
