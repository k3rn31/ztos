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

# ztos.rb
# This script retrieves the contacts form ZohoCRM using the API and generates
# multiple CSV files in the format that Skebby likes.
# The script gets the ZohoCRM authorization token from an environment variable,
# then it retrieves a JSON list of clients, and converts it in a Hash.
# Last, it converts it to multiple CSV files, one for each 'Lead Source'.

require 'net/http'
require 'json'

require 'ztos/skebby/skebby_file'
require 'ztos/string_utils'
require 'ztos/ztos_config'

module Ztos
  # The main class responsible of running the main task
  class Recorder
    def initialize(config)
      @config = config
      @crm_cli = []
      @skebby_files = {}
    end

    def retrieve_data_from_zoho
      # The ZohoCRM API limits max requests to 200,
      # so we get records 200 at a time
      from_index = 1
      to_index = 200

      uri = URI('https://crm.zoho.com/crm/private/json/Contacts/getRecords')

      print 'Getting data from ZohoCRM'
      loop do
        print '.'
        params = {
          newFormat: 2,
          authtoken: @config.zoho_token,
          scope: 'crmapi',
          fromIndex: from_index,
          toIndex: to_index,
          selectColumns: 'Contacts(Lead Source,First Name,Last Name,Email,Mobile)'
        }

        uri.query = URI.encode_www_form(params)

        response = Net::HTTP.get_response(uri)

        if response.is_a?(Net::HTTPSuccess)
          parsed_json = JSON.parse(response.body, symbolize_names: true)
          from_index += 200
          to_index += 200
        end

        break if parsed_json[:response][:nodata]

        parsed_json[:response][:result][:Contacts][:row].each do |row|
          h = {}
          row[:FL].each do |p|
            key = p[:val].extend(StringUtils)
            key.tokenify!
            h[key.to_sym] = p[:content]
          end
          @crm_cli << h
        end
      end
      print "\n"
    end

    def compose_records
      print 'Composing records'
      @crm_cli.each do |cli|
        print '.'
        lead = cli[:lead_source]
        lead.extend(StringUtils)
        lead.tokenify!
        @skebby_files[lead] ||= SkebbyTalker::File.new(lead + '.csv', 'w')
        @skebby_files[lead].puts "#{cli[:first_name]};#{cli[:last_name]};" \
          "#{cli[:email]};#{cli[:mobile]}"
      end
      print "\n"
      close_skebby_files
    end

    def close_skebby_files
      # Closing files
      puts 'Files generated:'
      @skebby_files.each do |_k, v|
        puts "\t" + File.basename(v)
        v.close
      end
    end
  end
end
