
# This software is distributed under MIT License
# 
# The MIT License (MIT)
# 
# Copyright (c) <2014> <Sebastien Delcroix (Seb)>
# Copyright (c) <2014> <Overkiz SAS>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'json'
require 'treetop'
require 'jsonpath/parser'
require 'jsonpath/nodes'

module JSONPath

  Parser = ::JSONPathGrammarParser
  class ParseError < ::SyntaxError; end

  def self.lookup(obj, path)
    parser = Parser.new
    if (result = parser.parse(path))
      result.walk(obj)
    else
      # raise ParseError, parser.failure_reason
      raise "#{ParseError} #{parser.failure_reason}"
    end
  end

end


class JsonPath

    def initialize(query)
        @query = query
    end

    def on(json_data)

        json_obj = JSON.parse(json_data)

        begin
            return JSONPath.lookup(json_obj,@query)
        rescue => err
            return "#{err} : #{@query}"
        end
    end

end
