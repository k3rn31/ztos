#!/usr/bin/env ruby

# crm_to_skebby.rb
# This script processes a CSV file exported from ZohoCRM and makes it suitable
# to import in Skebby.
# ZohoCRM exports a comma separated CSV  with a lot of columns. Skebby wants
# a semicolumn separated CSV. Also, the coumn names differ from ZohoCRM
# and Skebby. We want to use ony some columns from ZohoCRM and translate them
# in the Skebby format.

# Sets variables equal to ZohoCRM exported CSV column names.
# We only use the columns we need.
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
    # the CSV header in the Skebby format.
    # Again we only use the columns we need.
    puts 'nome;cognome;email;numero di cellulare'
  end
end

# Adds a little module utility to the String class to chomp on the right
module StringUtils
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
  row[lead_col].extend(StringUtils)
  lead = row[lead_col].rchomp('"').chomp('"')
  lead.gsub!(/\s+/, '_')
  skebby_files[lead] ||= SkebbyFile.new(lead + '.csv', 'w')
  skebby_files[lead].puts "#{row[name_col]};#{row[surname_col]};" \
    "#{row[email_col]};#{row[phone_col]}"
end

# Closing files
crm_csv.close
skebby_files.each { |_k, v| v.close }
