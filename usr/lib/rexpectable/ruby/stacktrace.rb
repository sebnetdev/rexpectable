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

require 'digest'
require 'json'
require 'base64'

class StackTrace 

    
    ROWS=   [
                { :id => { :info =>"ID", :format => '%c%ds' }},
                { :branch => { :info =>"Branch", :format => '%c%ds' } },
                ## Need to add Webservice type here : rest or soap
                { :object => { :info =>"Object", :format => '%c%ds' }},
                { :action => { :info =>"Action", :format => '%c%ds' }},
                { :timing => { :info =>"Ex. Time", :format => '%c%ds' }},
                { :rest_type => { :info =>"Type", :format => '%c%ds' }},
                { :is_expected => { :info =>"Is Exp", :format => '%c%ds' }},
                { :return_code => { :info =>"RetCo", :format => '%c%ds' }},
                { :expected_return_code => { :info =>"ERC", :format => '%c%ds' }},
                { :return_value => { :info =>"Ret Val", :format => '%c%ds' }},
                { :expected_value => { :info =>"Exp Val", :format => '%c%ds' }},
                { :status => { :info =>"Status", :format => '%c%ds' }},
                { :raw_ret_data => { :info =>"Raw Ret Data", :format => '%cs' }}
            ]



    def initialize(name='noname',regression=false)
        @linesep = false
        @stack = Array.new
        @raw_stack = Array.new
        @row_size = Hash.new
        ROWS.each do |row|
            row.each do |key,value|
                @row_size[key] = value[:info].length
            end
        end

        @failures = 0 # test failed
        @errors = 0 # code 0 or 500
        @tests = 0
        @total_time = 0
        @name = name
        @stack_id = 0

    end

    def add(branch,object,action,status,timing,rest_type="Nil",return_code="N/A",expected_return_code="N/A",return_value="N/A",expected_value="N/A",raw_ret_data="N/A",is_expected="N/A",junit=false)


        @tests += 1

        if raw_ret_data.length > 150
            raw_data_to_split = raw_ret_data[0..140]+'[...]'+raw_ret_data[-10..-1]
        else
            raw_data_to_split = raw_ret_data.clone
        end

        raw_data = to_str(raw_data_to_split).gsub(/\n/,' ')

        raw_splitted = raw_data.scan(/.{1,27}/)

        elapsed_time = timing[:stop] - timing[:start]

        @total_time += elapsed_time


        unless return_code.to_s == "N/A"

            if return_code == 0 or return_code >= 500
                @errors += 1
            elsif status == false
                @failures += 1
            end
        end

        @raw_stack << {
                        :id => @stack_id.to_s,
                        :branch => branch, 
                        :object => object, 
                        :action => action,
                        :timing => "%.3f" % [elapsed_time],
                        :rest_type => to_str(rest_type), 
                        :return_code => return_code, 
                        :expected_return_code => to_str(expected_return_code), 
                        :expected_value => to_str(expected_value), 
                        :return_value => to_str(return_value), 
                        :raw_ret_data => raw_ret_data.clone, 
                        :status => status,
                        :is_expected => is_expected,
                        :junit => junit
        }


        @stack << { 
                        :id => @stack_id.to_s,
                        :branch => branch, 
                        :object => object, 
                        :action => action,
                        :timing => "%.3f" % [elapsed_time],
                        :rest_type => to_str(rest_type), 
                        :return_code => to_str(return_code), 
                        :expected_return_code => to_str(expected_return_code), 
                        :expected_value => limitSize(to_str(expected_value)), 
                        :return_value => limitSize(to_str(return_value)), 
                        :raw_ret_data => raw_splitted[0], 
                        :status => to_str(status),
                        :is_expected => to_str(is_expected)
                    }

        if(raw_splitted.length > 1)
            for i in 1..raw_splitted.length-1
            @stack <<   {
                            :id => "",
                            :branch => "", 
                            :object => "", 
                            :action => "",
                            :timing => "",
                            :rest_type => "", 
                            :return_code => "", 
                            :expected_return_code => "", 
                            :expected_value => "", 
                            :return_value => "", 
                            :raw_ret_data => raw_splitted[i], 
                            :status => "",
                            :is_expected => ""

                        }
            end
        end

        @stack_id += 1
        #return (@stack.length)
    end


    def getRegressionKey()

        key_str = ""

        keys = Hash.new
        keys["tests"] = Array.new

        @raw_stack.each do |a_test|
            key_control = Digest::SHA1.hexdigest(a_test[:return_code].to_s+a_test[:expected_return_code].to_s+a_test[:expected_value].to_s+a_test[:return_value].to_s).to_str
            key_str << key_control
            keys["tests"] << key_control
        end

        keys["global"] = Digest::SHA1.hexdigest(key_str).to_str

        return keys
    end

    def hasRegression?(keys)

        new_keys =  getRegressionKey

        #puts "KEYS = #{new_keys["global"]} vs #{keys["global"]}"

        if new_keys["global"] == keys["global"]
            return true
        else
            return false
        end
    end




    def limitSize(str,size=20)

        proc_str = String.new(str)

        proc_str.gsub!(/\n/,' ')

        if proc_str.length <= size
            return proc_str
        end

        return proc_str[0..size-9]+'...'+proc_str[-5..-1]

    end

    def to_str(str)
        return str == nil ? "Nil" : str.to_s
    end

    def getAllStack()
        return @stack.clone
    end

    def calcRowSize
        @stack.each do |line|
            line.each do |key,value|
                @row_size[key] = [@row_size[key],value.length ].max
            end
        end
    end

    def getFormatter(sep=" | ")
        tmp = Array.new
        ROWS.each do |row|
            row.each do |key,value|
                tmp << value[:format] % ['%',@row_size[key]]
            end
        end

        return tmp.join(sep)
    end

    def getHeader
        tmp = Array.new
        ROWS.each do |row|
            row.each do |key,value|
                tmp << value[:info]
            end
        end

        return tmp
    end

    def getSeparator(sep="-")
        tmp = Array.new
        ROWS.each do |row|
            row.each do |key,value|
                tmp << sep * @row_size[key]
            end
        end

        return tmp
    end

    def getLine(line)
        tmp = Array.new
        ROWS.each do |row|
            row.each do |key,value|
                tmp << line[key]
            end
        end
        return tmp
    end

    def getFormattedExecStack
        calcRowSize
        formatter = getFormatter
        separator = getFormatter("-+-")
        separatorHeader = @linesep ? getFormatter("=|=") : getFormatter("-+-") 
        result = ""
        result << formatter % getHeader
        result << "\n"
        if ! @linesep
            result << separatorHeader % getSeparator
            result << "\n"
        end
        firstline=true
        @stack.each do |line|
            if @linesep && line[:id] != ""
                result << (firstline ? separatorHeader :  separator) % getSeparator(firstline ? '=' : '-')
                result << "\n"
                firstline=false
            end
            result << formatter % getLine(line)
            result << "\n"
        end

        return result

    end

    def printAllStack
        puts getFormattedExecStack
    end

    def setLinesep
        @linesep = true
    end

    def html

        dir=File.dirname(__FILE__)

        jsscript = ""
        [ "sorttable.min.js" , "jquery-1.10.2.min.js", "script.js"].each do |jsfile|
            #~ file = File.open(dir+"/../js/#{jsfile}","r")
            #~ jsscripttmp = ""
            #~ file.each do |a_line|
                #~ jsscripttmp << a_line
            #~ end
            #~ file.close

            jsscripttmp = Base64.encode64(File.read(dir+"/../js/#{jsfile}")).gsub("\n","")

            jsscript << "<script src=\"data:text/javascript;base64,#{jsscripttmp}\"></script>\n"
        end
        a_total_time = "%.3f" % [@total_time]
        result=<<-ENDOFTEXT
<!DOCTYPE html>
<html>
    <head>
        <meta charset="utf-8" />
        <style>
            .true
            {
                background-color: #FFFFFF;
            }
            .false
            {
                background-color: #FF6060;
            }
            .header
            {
                background-color: #CCCCCC;
            }
            table
            {
                border-collapse:collapse;
            }
            table,th, td
            {
                border: 1px solid black;
            }
            .cellContent
            {
                max-width : 250px;
                max-height: 150px;
                overflow: hidden;
            }
            .cellContentOpened
            {
               max-width : 250px;
            }
        </style>
        #{jsscript}
        <title>Rexpectable result of #{@name}</title>
    </head>
 
    <body>
    <h1>Synthesis</h1>
    <p>
    <table>
        <thead>
            <tr class="header"><th>failures</th><th>time</th><th>errors</th><th>tests</th><th>name</th></tr>
        </thead>
        <tbody>
            <tr><td>#{@failures}</td><td>#{a_total_time}</td><td>#{@errors}</td><td>#{@tests}</td><td>#{@name}</td></tr>
        </tbody>
    </table>
    </p>
    <h1>Details</h1>
    <p>
    <button id="hideTableLine">Click for magic</button>
    </p>
    <p>
    <table class="sortable">
ENDOFTEXT

        result << "<thead>\n"
        result << "<tr class=\"header\"><th>"+getHeader().join('</th><th>')+"</th></tr>\n"
        result << "</thead>\n"

        result << "<tbody>\n"

        tmp_stack = @raw_stack.clone

        tmp_stack.each do |test_case|

            [ :raw_ret_data , :return_value , :expected_value ].each do |data_name|
                test_case[data_name] = "<div class=\"cellContent\">"+test_case[data_name].to_s.gsub('<','&lt;').gsub('>','&gt;')+"</div>"
            end

            tr_class = Array.new

            tr_class << test_case[:status] == true ? 'true' : 'false'

            unless test_case[:junit]
                tr_class << "hidden"
            end
            #dbg_tmp = getLine(test_case).map {|x| x.to_s.encode.force_encoding("UTF-8")}.join('</td><td>')
            result << "<tr class=\""+tr_class.join(" ")+"\"><td>"+getLine(test_case).map {|x| x.to_s.encode.force_encoding("UTF-8")}.join('</td><td>')+"</td></tr>\n"
        end
        result << "</tbody>\n"
        result << "</table>\n</p>\n</body>\n</html>"

        return result
    end

    def json
        return JSON.pretty_generate(@raw_stack)
    end

    def jUnit

        a_total_time = "%.3f" % [@total_time]

        result = '<?xml version="1.0" encoding="UTF-8" ?>'+"\n"
        result << "<testsuite failures=\"#{@failures}\" time=\"#{a_total_time}\" errors=\"#{@errors}\" skipped=\"0\" tests=\"#{@tests}\" name=\"#{@name}\">\n"
        result << '  <properties><property name="http.agent" value="rexpectable"/></properties>'+"\n"
        
        @raw_stack.each do |test_case|

            unless test_case[:junit]
                next
            end

            result << "  <testcase time=\"#{test_case[:timing]}\" classname=\"#{test_case[:branch]}\" name=\"#{test_case[:object]}.#{test_case[:action]}(#{test_case[:rest_type]})\">\n"

            error_found = false

            if test_case[:return_code].to_s != "N/A"

                if test_case[:return_code] == 0 or test_case[:return_code] >= 500

                    if test_case[:return_code] == 0 
                        error_type='server is unreachable'
                    else
                        error_type='error server side'
                    end

                    result << "    <error message=\"#{test_case[:return_code].to_s}\" type=\"#{error_type}\"><![CDATA["+test_case[:raw_ret_data].to_s+"]]></error>\n"
                    error_found = true
                end
            end

            if error_found
                # nada
            elsif test_case[:status] == false
                result << '    <failure type="nothing"><![CDATA['+test_case[:raw_ret_data].to_s+"]]></failure>\n"
            else
                result << '    <system-out><![CDATA['+test_case[:raw_ret_data].to_s+"]]></system-out>\n"
            end
            result << "  </testcase>\n"
        end
        result << "</testsuite>\n"

        return result

    end

end
