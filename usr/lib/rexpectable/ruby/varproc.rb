# This software is distributed under MIT License
# 
# The MIT License (MIT)
# 
# Copyright (c) <2014> <Sebastien Delcroix (Seb)>
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


class VarReplace

    def initialize(vars)
        @vars = vars
    end


    def subs!(str)

        if str == nil
            str=""
        end

        if @vars == nil
            return
        end

        @vars.each do |a_var,a_value|
            subs="\#\{#{a_var}\}"
            str.gsub!(subs,a_value.to_s)
        end
    end

    def subs(str)

        str_tmp = str == nil ? "" : String.new(str)

        subs!(str_tmp)

        return str_tmp
    end

    def to_s()
        return @vars.to_s
    end

end


class VarSub

    ERR_CIRCULAR_REFERENCE="circular reference with two variables"
    ERR_NO_SUCH_VAR="No such variable"

    def initialize(definition)

        @definition = definition
        @process = Array.new
    end

    def parse
        
        order_list = Array.new
        @definition.each_key do |var|
            order_list.concat(processParsing(var))
        end
        var_found = Hash.new



        order_list.each do |var|
            if var_found.has_key?(var)
                next
            end
            @process << var
            var_found[var] = 0
        end
    end

    def get
        return @process
    end

    private

    def uniq(array)

        result = Hash.new

        array.each do |value|
            result[value] = 0
        end

        return result.each_key.to_a

    end


    def processParsing(var,level=0)
        if level >= 500
            raise "Too may loop in processParsing"
        end
        unless @definition.has_key?(var)
            raise "#{var} does not exist"
        end

        result = Array.new
        vars = @definition[var].scan /\#\{([^\}]+)\}/

        vars.each do |var_c|

            result = result.concat(processParsing(var_c[0],level+1))
        end
        result << var

        return result
    end

end
