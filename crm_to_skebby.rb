#!/usr/bin/env ruby

# zohocrm_to_skebby.rb
# This script retrieves the contacts form ZohoCRM using the API and generates
# multiple CSV files in the format that Skebby likes.
# The script gets the ZohoCRM authorization token from an environment variable,
# then it retrieves a JSON list of clients, and converts it in a Hash.
# Last, it converts it to multiple CSV files, one for each 'Lead Source'.

require 'net/http'
require 'json'

if ENV['ZOHO_TOKEN']
  ZOHO_TOKEN = ENV['ZOHO_TOKEN'].freeze
else
  STDERR.puts 'The ZOHO_TOKEN environmet variable isn\'t set. ' \
    'Please, get a valid token.'
  exit
end

# The class defining the CSV to import on Skebby
class SkebbyFile < File
  def initialize(filename, mode)
    super(filename, mode)
    # Every time we create a ne file, we insert
    # the CSV header in the Skebby format.
    # Again we only use the columns we need.
    puts 'nome;cognome;email;numero di cellulare'
  end
end

# Adds a little module utility to the String class to chomp on the right and
# tokenize strings
module StringUtils
  def rchomp(sep = $RS)
    start_with?(sep) ? self[sep.size..-1] : self
  end

  def tokenify
    rchomp('"').chomp('"')
    gsub!(/\s+/, '_')
  end
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
