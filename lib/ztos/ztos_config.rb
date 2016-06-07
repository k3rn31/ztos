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

require 'yaml'
require 'net/http'
require 'English'

require 'ztos/zoho/zoho_talker'

module Ztos
  # Primary configuration class
  class Configuration
    # This class loads configuration parameters from a configuration file
    # or from environment variables.
    # When it can't find them, it queries ZohoCRM for a new token.

    def initialize
      @config = { zoho_token: nil, zoho_last_access: nil }
      @config_file = File.expand_path('~/.ztos')
      if File.file?(@config_file)
        File.open(@config_file) { |file| @config = YAML.load(file).to_h }
      # elsif ENV['ZOHO_TOKEN']
      #   token_from_env
      else
        @config[:zoho_token] = Zoho::Talker.obtain_new_token
        save_config
      end
    end

    def zoho_token
      @config[:zoho_token]
    end

    def zoho_last_access
      @config[:zoho_last_access]
    end

    def save_config
      file = File.new(@config_file, 'w')
      file.puts @config.to_yaml
      file.close
    end

    private

    def token_from_env
      puts 'Using ZOHO_TOKEN environment variable.'
      @config[:zoho_token] = ENV['ZOHO_TOKEN']
    end
  end
end
