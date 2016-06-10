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
require 'ztos/ztos_logger'

module Ztos
  # The main class responsible of running the main task
  class Recorder
    def initialize
      @config = Configuration.new
      @logger = Logger.new
      @crm_cli = []
      @skebby_files = {}

      retrieve_data
      compose_records
    end

    private

    def retrieve_data
      @logger.do_with_log 'Getting data from ZohoCRM' do
        loop do
          print '.'
          response = ZohoTalker.ask_zoho_for_data(@config.zoho_token)
          break unless response
          parsed_json = JSON.parse(response, symbolize_names: true)
          break if parsed_json[:response][:nodata]
          populate_crm_cli(parsed_json)
        end
      end
    end

    def populate_crm_cli(parsed_json)
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

    def compose_records
      @logger.do_with_log 'Composing records' do
        @crm_cli.each do |cli|
          print '.'
          lead = switch_lead(cli)
          @skebby_files[lead] ||= SkebbyTalker::File.new(lead + '.csv', 'w')
          @skebby_files[lead].puts "#{cli[:first_name]};#{cli[:last_name]};" \
            "#{cli[:email]};#{cli[:mobile]}"
        end
      end
      close_skebby_files
    end

    def switch_lead(cli)
      lead = cli[:lead_source]
      lead.extend(StringUtils)
      lead.tokenify!
    end

    def close_skebby_files
      # Closing files
      @logger.do_with_log "Files generated:\n" do
        @skebby_files.each do |_k, v|
          puts "\t" + File.basename(v)
          v.close
        end
      end
    end
  end
end
