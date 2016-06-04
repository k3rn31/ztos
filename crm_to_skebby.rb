#!/usr/bin/env ruby

# crm_to_skebby.rb
# This script processes a CSV file exported from ZohoCRM and makes it suitable
# to import in Skebby.
#

# Sets variables equal to ZohoCRM exported CSV file. We only use the columns we
# need.
NAME_HEADER = 'Nome'.freeze
SURNAME_HEADER = 'Cognome'.freeze
PHONE_HEADER = 'Cellulare'.freeze
EMAIL_HEADER = 'E-mail'.freeze
LEAD_HEADER = '"Origine Lead"'.freeze

# The class defining the CSV to import on Skebby
class SkebbyFile < File
  def initialize(filename, mode)
    super(filename, mode)
    # Every time we create a ne file, we insert
    # the CSV header in the Skebby format
    puts 'nome;cognome;email;numero di cellulare'
  end
end

# Adds a little utility to the String class to chomp on the right
class String
  def rchomp(sep = $RS)
    start_with?(sep) ? self[sep.size..-1] : self
  end
end

abort('I need a valid file name.') if ARGV.empty? || !File.file?(ARGV[0])

skebby_files = {}
crm_csv = File.new(ARGV[0], 'r')

crm_header = crm_csv.gets.split(',')

name_col = crm_header.index(NAME_HEADER)
surname_col = crm_header.index(SURNAME_HEADER)
phone_col = crm_header.index(PHONE_HEADER)
email_col = crm_header.index(EMAIL_HEADER)
lead_col = crm_header.index(LEAD_HEADER)

crm_csv.each_line do |line|
  row = line.split(',')
  lead = row[lead_col].rchomp('"').chomp('"')
  lead.gsub!(/\s+/, '_')
  skebby_files[lead] ||= SkebbyFile.new(lead + '.csv', 'w')
  skebby_files[lead].puts "#{row[name_col]};#{row[surname_col]};" \
    "#{row[email_col]};#{row[phone_col]}"
end

# Closing files
crm_csv.close
skebby_files.each do |_k, v|
  v.close
end
