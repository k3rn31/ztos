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

require 'ztos/skebby_file'
require 'ztos/string_utils'

if ENV['ZOHO_TOKEN']
  ZOHO_TOKEN = ENV['ZOHO_TOKEN'].freeze
else
  STDERR.puts 'The ZOHO_TOKEN environmet variable isn\'t set. ' \
    'Please, get a valid token.'
  exit
end

crm_cli = []
skebby_files = {}

# The ZohoCRM API limits max requests to 200, so we get records 200 at a time
from_index = 1
to_index = 200

uri = URI('https://crm.zoho.com/crm/private/json/Contacts/getRecords')

print 'Getting data from ZohoCRM'
loop do
  print '.'
  params = {
    newFormat: 2,
    authtoken: ZOHO_TOKEN,
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
      key.tokenify
      h[key.to_sym] = p[:content]
    end
    crm_cli << h
  end
end
print "\n"

print 'Composing records'
crm_cli.each do |cli|
  print '.'
  lead = cli[:Lead_Source]
  lead.extend(StringUtils)
  lead.tokenify
  skebby_files[lead] ||= SkebbyFile.new(lead + '.csv', 'w')
  skebby_files[lead].puts "#{cli[:First_Name]};#{cli[:Last_Name]};" \
    "#{cli[:Email]};#{cli[:Mobile]}"
end
print "\n"

# Closing files
puts 'Files generated:'
skebby_files.each do |_k, v|
  puts "\t" + File.basename(v)
  v.close
end
