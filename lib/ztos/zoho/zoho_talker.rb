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

module Zoho
  # Base class interface to talk with ZohoCRM
  class Talker
    ERROR_RESPONSES = %w(INVALID_PASSWORD
                         NO_SUCH_USER
                         EXCEEDED_MAXIMUM_ALLOWED_AUTHTOKENS).freeze

    @login = { username: nil, password: nil }

    class << self
      def obtain_new_token
        puts 'Can\'t find a valid ZohoCRM authtoken. Obtaining new one.'
        ask_for_token
      end

      private

      def new_username
        print 'Enter ZohoCRM username: '
        @login[:username] = gets.chomp
      end

      def new_password
        print 'Enter ZohoCRM password: '
        @login[:password] = gets.chomp
      end

      def new_credentials
        new_username
        new_password
      end

      def generate_uri
        uri = URI('https://accounts.zoho.com/apiauthtoken/nb/create')
        params = {
          SCOPE: 'ZohoCRM/crmapi',
          EMAIL_ID: @login[:username],
          PASSWORD: @login[:password],
          DISPLAY_NAME: 'Ztos'
        }
        uri.query = URI.encode_www_form(params)
        uri
      end

      def ask_for_token
        token = nil
        until token
          new_credentials
          uri = generate_uri
          response = Net::HTTP.get_response(uri).body.split($RS)[2].split('=')
          next unless (response & ERROR_RESPONSES).empty?
          token = response[1]
        end
        token
      end
    end
  end
end
