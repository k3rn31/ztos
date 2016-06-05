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

# Adds a little module utility to the String class
module StringUtils
  # Adds a little module utility to the String class to chomp on the right and
  # tokenize strings
  #
  # Arguments:
  #   sep: (string)

  def rchomp(sep = $RS)
    start_with?(sep) ? self[sep.size..-1] : self
  end

  def tokenify
    rchomp('"').chomp('"')
    gsub!(/\s+/, '_')
  end
end
