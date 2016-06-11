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

require 'ztos/ztos_logger'

# Module responsible of Skebby communications
module SkebbyTalker
  @skebby_files = {}

  # The class defining the CSV to import on Skebby
  class File < File
    # Creates a file that when initializes, adds a header.
    #
    # Arguments:
    #   filename: (String)
    #   mode: (String)

    def initialize(filename, mode)
      super(filename, mode)
      # Every time we create a ne file, we insert
      # the CSV header in the Skebby format.
      # Again we only use the columns we need.
      puts 'nome;cognome;email;numero di cellulare'
    end
  end

  def self.write_files(lead, cli)
    @skebby_files[lead] ||= File.new(lead + '.csv', 'w')
    @skebby_files[lead].puts "#{cli[:first_name]};#{cli[:last_name]};" \
      "#{cli[:email]};#{cli[:mobile]}"
  end

  def self.close_files
    # Closing files
    Ztos::Logger.do_with_log "Files generated:\n" do
      @skebby_files.each do |_lead, file|
        puts "\t" + File.basename(file)
        file.close
      end
    end
  end
end
