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

require 'varproc'
require 'tmpdir'
require 'digest'
require 'rest_client'
require 'jsonpathcompat'
require 'json'
require 'rexml/document'
include REXML


class RestResponse

    attr_reader :code, :body, :cookies, :headers

    def initialize(code=nil,body=nil,cookies=nil,headers=nil)
        set(code,body,cookies,headers)
    end
    
    def set(code=nil,body=nil,cookies=nil,headers=nil)
        @code = code
        @body = body
        @cookies = cookies
        @headers = headers
    end

end


class RestRequest

    def initialize(type)
        @type = type
    end

    def get(url,params,cookies)

        begin
            RestClient.get(url, {  :content_type => @type, :accept => @type, :params => params , :cookies => cookies, :ssl_version => :TLSv1}) { |response,request,result,&block|
                return RestResponse.new(response.code,response.to_str,response.cookies,response.headers)
            }
        rescue => e
            return RestResponse.new(0,e.to_s,nil,nil)
        end
    end

    def delete(url,params,cookies)

        begin
            RestClient.delete(url, {  :content_type => @type, :accept => @type, :params => params , :cookies => cookies, :ssl_version => :TLSv1}) { |response,request,result,&block|
                return RestResponse.new(response.code,response.to_str,response.cookies,response.headers)
            }
        rescue => e
            return RestResponse.new(0,e.to_s,nil,nil)
        end
    end

    def put(url,params,cookies,multipart=false,multipart_param_name=nil,body_parameter_content_type=nil)
        return verb(url,:put,params,cookies,multipart,multipart_param_name,body_parameter_content_type)
    end

    def post(url,params,cookies,multipart=false,multipart_param_name=nil,body_parameter_content_type=nil)
        return verb(url,:post,params,cookies,multipart,multipart_param_name,body_parameter_content_type)
    end

    private

    def verb(url,verb_type,params,cookies,multipart,multipart_param_name,body_parameter_content_type)

        tmpdir = nil
        fd = nil
        dest_file = nil
        name = ""
        if multipart
            if params.class == Hash
                params[:multipart] = true
            else
                warn "multipart declared but not used. Please use body_parameter_name or remove multipart = true"
            end
            if multipart_param_name != nil
                tmpdir = Dir.tmpdir
                enc = nil
                if body_parameter_content_type != nil
                    enc = body_parameter_content_type.split('/')[1]
                else
                    enc = @type.to_s
                end
                while File.exists?("#{tmpdir}/#{name}")
                    name = "RESTEST.Multipartbody.#{rand(1000000)}.#{enc}"
                end
                dest_file = "#{tmpdir}/#{name}"
                fd = File.new(dest_file,"w+b")
                fd.write(params[multipart_param_name])
                params[multipart_param_name] = fd
                fd.rewind
            end
        end
    

        rest_resp = RestResponse.new

        begin
            #~ request = RestClient::Request.new(
                #~ :method => verb_type,
                #~ :url => @url,
                #~ #:content_type => @type,
                #~ :contenfft_type => "application/xml",
                #~ :accept => @type,
                #~ :cookies => cookies,
                #~ :payload => params )      
            #~ response = request.execute
#~ 
            #~ rest_resp.set(response.code,response.to_str,response.cookies,response.headers)
            case verb_type 
            when :post
                RestClient.post(url, params, {  :content_type => @type, :accept => @type,  :cookies => cookies, :ssl_version => :TLSv1}) { |response,request,result,&block|
                    rest_resp.set(response.code,response.to_str,response.cookies,response.headers)
                }
            when :put
                RestClient.put(url, params, {  :content_type => @type, :accept => @type,  :cookies => cookies, :ssl_version => :TLSv1}) { |response,request,result,&block|
                    rest_resp.set(response.code,response.to_str,response.cookies,response.headers)
                }
            end
        rescue => e
            rest_resp.set(0,e.to_s,nil,nil)
        end

    if dest_file != nil
        File.unlink(dest_file)
    end

    return rest_resp

    end

end

class Restest


    XML=0x01
    JSON=0x02


    EXPECTED_CODE_ONLY="code_only"   # an expected return code only 
    EXPECTED_TYPE="type"   # a value expected well typed
    EXPECTED_VALUE="value"  # a value well type and with exact match
    EXPECTED_RANGE="range"  # a range of values well typed
    EXPECTED_REGEXP="regexp" # a regexp



    EXPECTED_LIST = { 
                        EXPECTED_CODE_ONLY => 0,
                        EXPECTED_TYPE => 0,
                        EXPECTED_VALUE => 0,
                        EXPECTED_RANGE => 0,
                        EXPECTED_REGEXP => 0
                    }

    TYPE_INT="int"
    TYPE_FLOAT="float"
    TYPE_BOOLEAN="boolean"
    TYPE_STRING="string"
    TYPE_IPV4="ipv4"

    TYPE_LIST = {
                    TYPE_INT => 0,
                    TYPE_FLOAT => 0,
                    TYPE_BOOLEAN => 0,
                    TYPE_STRING => 0,
                    TYPE_IPV4 => 0
                }

    @@session_cookies = { :default => {} }
    @@session_parameters = { :default => {} }
    @@global_var = Hash.new

    [ :json, :xml].each do |ws_type|
        @@session_cookies[:default][ws_type] = Hash.new
        @@session_parameters[:default][ws_type] = Hash.new
        @@global_var[ws_type] = Hash.new
    
    end

    @@functions = Hash.new

    def initialize(test_desc,url,expected_return_code,expected,expected_type,
                    expected_data,path,params,session_id=:default,is_expected=true,
                    body=nil,body_parameter_name=nil,multipart=false,body_parameter_content_type=nil,content_type_json=nil,content_type_xml=nil)

        # test_desc : description for report
        # request_type : XML or JSON or both
        # url : https://fqdn/path/to/api
        # expected_return_code = 200, 400, 401, etc.
        # expected      : which kind of data is expected (return code, type, value (typed) range, or regexp)
        # expected_type : type of data
        # expected_data : real expected data, (except for type and code obviously)
        # path : path to get info => hash with path for XML and/or JSON
        #        use jsonpath and xpath syntax
        #        you can use var example : :xml => { :var1 => '/path/to/node' , :var2 => '/path/to/node2' , :_result => '#{var1}//#{var2}' }
        #        _result is the ultimate result, it can be alone

        @check = Hash.new
        @path = Hash.new
        @rest_req = Hash.new
        @result_return_code = Hash.new
        @result_exepected_data = Hash.new
        @allvars = Hash.new
        @allvars[:xml] = Hash.new
        @allvars[:json] = Hash.new
        @allrawvars = Hash.new
        @allrawvars[:xml] = Hash.new
        @allrawvars[:json] = Hash.new
        @url = url.clone
        @test_desc = test_desc

        if expected_return_code.class == Array
            @expected_return_code = expected_return_code.clone
        elsif expected_return_code.class == String
            @expected_return_code = expected_return_code.split(',').map { |e| e.to_i }
        else
             @expected_return_code = [ expected_return_code ]
        end
        @expected = expected
        @expected_type = expected_type
        @expected_data = typeTransform(expected_data)
        @session_id = session_id
        if params != nil
            @params = params.clone
        else
            @params = nil
        end

        @rest_type = nil

        @rest_response = Hash.new

        url.each_key do |request_type|
            if request_type == :xml
                if content_type_xml == nil
                    @rest_req[:xml] = RestRequest.new(:xml)
                else
                    @rest_req[:xml] = RestRequest.new(content_type_xml)
                end
                @result_return_code[:xml] = false
                @result_exepected_data[:xml] = false
                if path != nil
                    @path[:xml] = path[:xml]
                end

                if @rest_type == nil
                    @rest_type = :xml
                end
            end
               
            if request_type == :json
                if content_type_json == nil
                    @rest_req[:json] = RestRequest.new(:json)
                else
                    @rest_req[:json] = RestRequest.new(content_type_json)
                end
                @result_return_code[:json] = false
                @result_exepected_data[:json] = false
                if path != nil
                    @path[:json] = path[:json]
                end
                @rest_type = :json # default value  => json

            end     
        end

        @is_expected = is_expected


        @body = body == nil ? body : body.clone
        
        @body_parameter_name = body_parameter_name
        
        @multipart = multipart
        
        @body_parameter_content_type = body_parameter_content_type

    end


    def expectedOperation(trueorfalse)
        @is_expected = trueorfalse
    end


    def self.addFunction(name,type,param1,param2)
    
        if @@functions.has_key?(name)
            return false
        end
        
        @@functions[name] = Hash.new
        @@functions[name][:type] = type.to_sym
        @@functions[name][:param1] = param1
        @@functions[name][:param2] = param2
        return true
    end

    def self.newSessionID()

        hash=""

        begin
            key = Time.now.to_s
            hash = Digest::SHA1.hexdigest(key)
        end while @@session_cookies.has_key?(hash)

        @@session_cookies[hash] = Hash.new

        @@session_cookies[hash][:json] = Hash.new
        @@session_cookies[hash][:xml] = Hash.new

        @@session_parameters[hash] = Hash.new
        @@session_parameters[hash][:json] = Hash.new
        @@session_parameters[hash][:xml] = Hash.new

        return hash
    end

    def getRestType()
        return @rest_type
    end

    def getExpectedValue()
        return @expected_data
    end

    def getExpectedReturnCode()
        return @expected_return_code
    end

    def getReturnCode()
        return @rest_response[@rest_type].code
    end

    def getReturnValue()
        return @rest_response[@rest_type].body
    end

    def switchToJSON()
        @rest_type = :json
        return true
    end

    def setGlobalVar(vars)
        @@global_var[@rest_type] = Hash.new

        vars.each do |key,value|
            @@global_var[@rest_type]['@'+key] = value
        end

    end

    def setBody(body,rest_type=nil)
        if body.class == Hash
            @body = body.clone
        else
            if rest_type == nil
                rest_type = @rest_type
            end

            @body[rest_type] = body.to_s

        end

    end


    def setExpectedData(data)
        @expected_data = data
    end

    def checkAllResult()
        if @rest_req.has_key?(:xml) && @rest_req.has_key?(:json)
            var_xml = getVar("_result",:xml) 
            var_json = getVar("_result",:json)
            if var_xml != var_json
                return false
            end
        end

        return true
    end

    def switchToXML()
        @rest_type = :xml
        return true
    end

    def clearCookies()
        @@session_cookies[@session_id][@rest_type] = Hash.new
        return true
    end


    def saveSessionParameter(name,var)
        @@session_parameters[@session_id][@rest_type][name] = getVar(var)
        return true
    end

    def clearSessionParameters()
        @@session_parameters[@session_id][@rest_type] = Hash.new
        return true 
    end

    def mergeCookies()
        if @rest_response[@rest_type].cookies != nil
            @@session_cookies[@session_id][@rest_type].merge!(@rest_response[@rest_type].cookies)
        end
    end


    def mergeParameters()

        params = Hash.new
        
        if @params != nil
            params = @params.clone
        end
        
        if @body_parameter_name != nil && @body[@rest_type] != nil
            params[@body_parameter_name] = @body[@rest_type]
        end
        
        params.merge!(@@session_parameters[@session_id][@rest_type])
        replace = VarReplace.new(@@global_var[@rest_type])
        params.each do |key,value|
            params[key] = replace.subs(value.to_s)
        end

        if @body[@rest_type] == nil || @body_parameter_name != nil
            return params
        else
            replace = VarReplace.new(@@global_var[@rest_type])
            returned_value = replace.subs(@body[@rest_type])
            replace = VarReplace.new(params)
            returned_value = replace.subs(returned_value)

            return returned_value
            # return a String because it returns a raw body
        end
    end

    def urlVarSub()
        replace = VarReplace.new(@@global_var[@rest_type])
        return replace.subs(@url[@rest_type])
    end

    def get()
        @rest_response[@rest_type] = @rest_req[@rest_type].get(urlVarSub(),mergeParameters(),@@session_cookies[@session_id][@rest_type])
        mergeCookies
        return expect?
    end

    def delete()
        @rest_response[@rest_type] = @rest_req[@rest_type].delete(urlVarSub(),mergeParameters(),@@session_cookies[@session_id][@rest_type])
        mergeCookies
        return expect?
    end

    def put()
        @rest_response[@rest_type] = @rest_req[@rest_type].put(urlVarSub(),mergeParameters(),@@session_cookies[@session_id][@rest_type],@multipart,@body_parameter_name,@body_parameter_content_type)
        mergeCookies
        return expect?    
    end

    def post()
        @rest_response[@rest_type] = @rest_req[@rest_type].post(urlVarSub(),mergeParameters(),@@session_cookies[@session_id][@rest_type],@multipart,@body_parameter_name,@body_parameter_content_type)
        mergeCookies
        return expect?    
    end

    def getVar(var="_result",a_rest_type=@rest_type)

        return typeTransform(@allvars[a_rest_type][var])
    end

    def getRawVar(var="_result",a_rest_type=@rest_type)

        if a_rest_type == :json
            return @allrawvars[a_rest_type][var].to_s
        else
            return @allrawvars[a_rest_type][var].to_s
        end
    end    

    def setParam(param_name,value)
        if @params == nil
            @params = Hash.new
        end
        @params[param_name] = value
        return true
    end

    private

    def expect?()
        @result_return_code[@rest_type] = isExpectedReturnCode?
        buildExpectedData
        @result_exepected_data[@rest_type] = isExpected?

        if @is_expected
            return (@result_return_code[@rest_type] && @result_exepected_data[@rest_type])
        else
            if @expected == EXPECTED_CODE_ONLY
                return ! @result_return_code[@rest_type]
            else
                return @result_return_code[@rest_type] &&  ( ! @result_exepected_data[@rest_type])
            end
        end
    end

    def isExpectedReturnCode?


        @expected_return_code.each do |code_to_test|
            if code_to_test == @rest_response[@rest_type].code
                return true
            else
                break
            end
        end

        return false 
    end

    def isExpected?


        if @expected == EXPECTED_CODE_ONLY
            return true
        elsif @expected == EXPECTED_TYPE

            return isGoodType?      
        elsif  @expected == EXPECTED_VALUE
            if not isGoodType?
                return false
            end
            
            ###### Modify here #####
            
            expected_data_tmp = @expected_data
            
            if @expected_data.class == String.new.class
                replace_gv = VarReplace.new(@@global_var[@rest_type])
                expected_data_tmp = replace_gv.subs(@expected_data)
            end
            #if getExpectedData == @expected_data
            if getExpectedData == expected_data_tmp
                return true
            else
                return false
            end
        elsif  @expected == EXPECTED_RANGE
            if not isGoodType?
                return false
            end

            return isInRange?

        elsif  @expected == EXPECTED_REGEXP
            return isMatch? 
        else
            return false
        end

        return true # anyway
    end

    def typeTransform(data)



        if data == nil
            return nil
        end

        if @expected == EXPECTED_TYPE or @expected == EXPECTED_VALUE
            case @expected_type

            when TYPE_BOOLEAN
                if data.class != TrueClass && data.class != FalseClass
                    if (data.to_s =~ /(true|t|yes|y|1)$/i)
                        data =  true
                    elsif (data.to_s =~ /(false|f|no|n|0)$/i)
                        data = false
                    end
                end
            when TYPE_INT
                if data.class != Fixnum
                    data=data.to_s.to_i
                end
            when TYPE_FLOAT
                if data.class != Float
                    data=data.to_f
                end

            when TYPE_STRING
                if data.class != String
                    data = data.to_s
                end
            end

        end


        return data

    end


    def splitData(data)
        match_data = data.scan(/^(path|var|function\.[a-zA-Z_][a-zA-Z_0-9]*):(.*)$/)
        if match_data == nil
            return nil,nil
        end

        result = Array.new
        result << match_data[0][0]
        result << match_data[0][1]
        return result
    end

    def buildExpectedData

        #enable


        if @path[@rest_type] == nil
            return

        end

        var_list = @path[@rest_type].clone

        replace_gv = VarReplace.new(@@global_var[@rest_type])


        var_list.each do |var,value|
            var_list[var] = replace_gv.subs(value)
        end

        vars = VarSub.new(var_list)
        vars.parse
        vars.get.each do |var|
            command,data = splitData(var_list[var])
            str=data
            if str == nil
                next
            end
            match_list = data.scan(/\#\{([^\}]+)\}/)
            if match_list.length > 0
                match_list.each do |my_var|
                    a_var = my_var[0]
                    subs="\#\{#{a_var}\}"
                    new_str = ""
                    if var_list[a_var] == nil
                        new_str = str.gsub(subs,"")
                    elsif var_list[a_var].class == TrueClass || var_list[a_var].class == FalseClass
                        new_str = str.gsub(subs,var_list[a_var] ? "true" : "false")
                    elsif
                         new_str = str.gsub(subs,var_list[a_var].to_s)   
                    end
                    str=new_str
                end

            end
            result = str
            if command == "path"
                if @rest_type == :json
                    jsonpath = JsonPath.new(str)
                    begin
                        tmp = jsonpath.on(@rest_response[@rest_type].body)
                        #result = tmp[0]
                        result = tmp.join(',')
                    rescue => e
                        result = e.to_s
                    end
                else 
                    begin
                        xmldoc = Document.new(@rest_response[@rest_type].body)
                        # Info for the first movie found
                        #result = XPath.match(xmldoc, str).join(',')
                        result = XPath.match(xmldoc, str).join(',')
                    rescue
                        result = e.to_s
                    end
                end
            elsif command =~ /^function\..*$/
                matching = command.match(/^function\.([a-zA-Z_][a-zA-Z_0-9]*)$/)
                function_name = matching[1]
                
                if @@functions.has_key?(function_name)
                
                    case @@functions[function_name][:type]
                    
                    when :regexp

                        re = Regexp.new(@@functions[function_name][:param2])
                        
                        matching = re.match(str)
                        if matching != nil
                        index = @@functions[function_name][:param1].to_i

                            result = matching[index] != nil ? matching[index] : ""
                        else
                            result = ""
                        end
                    
                    when :split
                        result = str.split(@@functions[function_name][:param2])[@@functions[function_name][:param1].to_i]
                        result = "" if result == nil
                    end
                
                end
            end


            var_list[var] = result

        end


        var_list.each_key do |a_var|
            begin
                @allrawvars[@rest_type][a_var] = var_list[a_var].clone
            rescue
                @allrawvars[@rest_type][a_var] = var_list[a_var]
            end
            @allvars[@rest_type][a_var] =  typeTransform(var_list[a_var])
        end


        #return typeTransform(var_list["_result"])

    end

    def getExpectedData
        return @allvars[@rest_type]['_result']
    end

    def isMatch?
        
        re = Regexp.new(@expected_data)

        if getExpectedData == nil
            return false
        end

        if getExpectedData.to_s.match(re)
            return true
        end

        return false

    end

    def isInRange?

        data_tmp = @expected_data.scan(/^([\[\]])([^\;]+);([^\[\]]+)([\[\]])/)
        data = data_tmp[0]

        if data[0] == '['
            inc_min = true
        else
            inc_min = false
        end

        if data[3] == ']'
            inc_max = true
        else
            inc_max = false
        end

        case @expected_type

            when TYPE_INT

                min_value = data[1].to_i
                max_value = data[2].to_i
                value = getExpectedData.to_i

            when TYPE_FLOAT

                min_value = data[1].to_f
                max_value = data[2].to_f
                value = getExpectedData.to_f
        end    


        if (value < min_value) or (value > max_value)
            return false
        end

        if ! inc_min && (value == min_value)
            return false
        end

        if ! inc_max && (value == max_value)
            return false
        end

        return true

    end

    def isGoodType?
        case @expected_type

            when TYPE_INT
                data = getExpectedData

                if data.class == Fixnum
                    return true
                end

                data=data.to_s

                if data.class == String && data =~ /^-?[0-9]+$/

                   return true
                else

                    return false
                end

            when TYPE_FLOAT
                data = getExpectedData

                if data.class == Float
                    return true
                end

                if  data.class == String && data =~ /^-?[0-9]+\.[0-9]+$/
                    return true
                else
                    return false
                end

            when TYPE_BOOLEAN
                value = getExpectedData

                if value.class == TrueClass || value.class == FalseClass
                    return true
                else
                    return false
                end

            when TYPE_STRING
                data = getExpectedData

                if data.class == String
                    return true
                else
                    return false
                end

        end

        return false

    end

end

