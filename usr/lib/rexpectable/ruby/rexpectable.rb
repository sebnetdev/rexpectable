
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

require 'restest'
require 'stacktrace'
require 'uri'


class Rexpectable


    REST_KEYWORDS_SIMPLE = { 
                                'description' => { :required => false , :default => nil}, 
                                'expected_description' => { :required => false , :default =>nil}, 
                                'url.json' => { :required => false , :default =>nil},  
                                'url.xml' => { :required => false , :default =>nil}, 
                                'return_code' => { :required => false , :default =>200}, 
                                'expected' => { :required => true , :default =>nil}, 
                                'expected_type' => { :required => false , :default =>nil}, 
                                'expected_data' => { :required => false , :default =>nil}, 
                                'loop.retry' => { :required => false , :default =>1}, 
                                'loop.between_retry' => { :required => false , :default =>0},
                                'is_expected' => { :required => false , :default =>true},
                                'body_parameter_name' => { :required => false , :default =>nil},
                                'multipart' => { :required => false , :default =>false},
                                'body_parameter_content_type' => { :required => false , :default =>nil},
                                'body.xml' => { :required => false , :default =>nil},
                                'body.json' => { :required => false , :default =>nil},
                                'content_type.json' => { :required => false , :default =>nil},
                                'content_type.xml' => { :required => false , :default =>nil}
                            }

    REST_KEYWORDS_MULTI =  { 
                                'path.json' => { :required => false , :default =>nil}, 
                                'path.xml' => { :required => false , :default =>nil}, 
                                'params' => { :required => false , :default =>nil},
                                'function' => { :required => false , :default =>nil}
 
                            }

    RESERVED_WORDS = {
                        'self' => 0,
                        'null' => 0
                     }

    REST_METHODS =  {
                        'get' => 0,
                        'put' => 0,
                        'delete' => 0,
                        'post' => 0
                    }

    AUTHORIZED_METHODS =    {
                                'getVar' => 0,
                                'run' => 0,
                                #'setParam' => 0,
                                'setVarToParam' => 0,
                                'saveSessionParameter' => 0,
                                'clearSessionParameters' => 0,
                                'clear' => 0,
                                'checkAllResult' => 0,
                                'setBody' => 0,
                                'setVarToExpectedData' => 0
                            }

    BRANCH_DEFAULT_CONFIG = {
                                :stopon => 'nostop',
                            }

    STOPON = { 'firsterrorforall' =>1, 'firsterror' => 1, 'nostop' => 1 }

    def initialize(filename,name=nil,macro_var=Hash.new,overridden_params=Hash.new,inclued_files=Array.new)
        @filename = filename
        @rest_list = Hash.new
        @branch_list = Hash.new
        @error= Array.new
        @parsed = false
        @parsing_ok = false
        @session_cookies_id = Restest::newSessionID
        @internal_vars = Hash.new
        @testname = name == nil ? "" : name
        @stack = @testname == "" ? StackTrace.new(File.basename(@filename)) : StackTrace.new(@testname)
        @verbose = false
        @stoponforall = false
        @macro_var_overridden = Hash.new
        @timing = Hash.new
        if macro_var == nil
            @macro_var = Hash.new
        else
            @macro_var = macro_var.clone
            @macro_var.each_key do | a_macro_var |
                @macro_var_overridden[a_macro_var] = 1
            end
        end

        if overridden_params==nil
            @overridden_params = Hash.new
        else
            @overridden_params = overridden_params.clone
        end

        @inclued_files = inclued_files.clone

    end


    def parse()
        verbose("Starting parsing file '#{@filename}' ... ")

        #building a null rest object to perform switchtoXML/JSON call clear session_cookies params etc.

        @rest_list['null'] = Hash.new
        @rest_list['null'] = { 'description' => "null" , "url.json" => 'http://localhost/', "url.xml" => "http://localhost/", "return_code" => 200, "expected" => "code_only"}

        return_value = true

        @inclued_files.each do |file_to_parse|
            return_value = return_value && _parse(file_to_parse)
        end

        return_value = return_value && _parse()

        return_value = return_value && interpreter()

        if return_value
            verbose("OK")
        else
            verbose("FAILED")
        end

        verbose("\n")

        return return_value
    end

    def enableVerbose()
        @verbose = true
    end
    
    def getError()
        return @error.join("\n")+"\n"
    end

    def run(branch='main')

        verbose("Checking parsing of file '#{@filename}' ... ")

        unless @parsing_ok && @parsed
            setError("Can't run parsing failed || not done")
            verbose("FAILED, not parsed or parsing was failed\n")
            return false
        end

        verbose("OK\n")

        verbose("Building internal objects ... ")

        verbose("OK\n")
        verbose("Starting execution ... ")
        return_value = execute(branch)

        if return_value
            verbose("OK\n")
        else
            verbose("FAILED\n")
        end

        return return_value

    end


    def getRegressionKey()
        return @stack.getRegressionKey()
    end

    def checkRegression(key)
        return_value = @stack.hasRegression?(key)
        unless return_value
            setError("Regression key [#{key}] is not the same")
        end

        return return_value
    end

    def getExecStack()
        return @stack.getAllStack
    end

    def getJUnit()
        return @stack.jUnit
    end

    def getJSON()
        return @stack.json
    end

    def getHTML()
        return @stack.html
    end

    def clearExecStack()
        @stack = @testname == "" ? StackTrace.new(File.basename(@filename)) : StackTrace.new(@testname)
    end

    def getFormattedExecStack()
        return @stack.getFormattedExecStack
    end

    def printExecStack()
        @stack.printAllStack
    end

    def setLinesep()
        @stack.setLinesep
    end

    def get(rest_obj,branch='@RUBY')
        return verbExec(rest_obj,branch,"get")
    end

    def post(rest_obj,branch='@RUBY')
        return verbExec(rest_obj,branch,"post")
    end

    def delete(rest_obj,branch='@RUBY')
        return verbExec(rest_obj,branch,"delete")
    end

    def put(rest_obj,branch='@RUBY')
        return verbExec(rest_obj,branch,"put")
    end


    def getThisVar(rest_obj,var)
        return @exec_rest_object[rest_obj].getVar(var)
    end

    def getVar(rest_obj,int_var,var,branch='@RUBY')

        startTiming(rest_obj)

        #@internal_vars[int_var] = @exec_rest_object[action[:object]].getVar(remote_var)
        @internal_vars[int_var] = @exec_rest_object[rest_obj].getVar(var)
        result_p=true
        if @internal_vars[int_var] == nil
            result_p = false
        end
        @exec_rest_object[rest_obj].setGlobalVar(@internal_vars)
        stopTiming(rest_obj)


        @stack.add(branch,rest_obj,"getVar",result_p,@timing[rest_obj],@exec_rest_object[rest_obj].getRestType,"N/A","N/A",@internal_vars[int_var],"N/A","N/A","N/A",true)

        return result_p        
    end

    def setParam(rest_obj,param_name,value,branch='@RUBY')
        startTiming(rest_obj)

        result_p = true
        @exec_rest_object[rest_obj].setParam(param_name,value)
        stopTiming(rest_obj)
        @stack.add(branch,rest_obj,"setParam",result_p,@timing[rest_obj],"Nil","N/A","N/A","N/A","N/A","N/A","N/A",true)
        return result_p
    end
    
    def setValueToVar(rest_obj,int_var,value,branch='@RUBY')
        startTiming(rest_obj)
        result_p = true
        @internal_vars[int_var] = value
        @exec_rest_object[rest_obj].setGlobalVar(@internal_vars)
        stopTiming(rest_obj)
        @stack.add(branch,rest_obj,"setValueToVar",result_p,@timing[rest_obj],"Nil","N/A","N/A","N/A","N/A","N/A","N/A",true)
        return result_p
    end

    def setVarToParam(rest_obj,int_var,param_name,branch='@RUBY')
        startTiming(rest_obj)

        result_p = true
        if @internal_vars.has_key?(int_var)
            @exec_rest_object[rest_obj].setParam(param_name,@internal_vars[int_var])
        else
            result_p=false
        end
        stopTiming(rest_obj)
        @stack.add(branch,rest_obj,"setVarToParam",result_p,@timing[rest_obj],"Nil","N/A","N/A","N/A","N/A","N/A","N/A",true)
        return result_p
    end

    def setVarToExpectedData(rest_obj,int_var,branch='@RUBY')
        startTiming(rest_obj)

        result_p = true
        if @internal_vars.has_key?(int_var)
            @exec_rest_object[rest_obj].setExpectedData(@internal_vars[int_var])
        else
            result_p=false
        end
        stopTiming(rest_obj)
        @stack.add(branch,rest_obj,"setVarToExpectedData",result_p,@timing[rest_obj],@exec_rest_object[rest_obj].getRestType,"N/A","N/A",@internal_vars[int_var],"N/A","N/A","N/A",true)
        return result_p
    end

    def setBody(rest_obj,an_object,remote_var,branch='@RUBY')
        startTiming(rest_obj)

        result_p = true
        if @rest_list.has_key?(an_object)
            @exec_rest_object[rest_obj].setBody(@exec_rest_object[an_object].getRawVar(remote_var))
        else
            result_p=false
        end
        stopTiming(rest_obj)
        @stack.add(branch,rest_obj,"setBody",result_p,@timing[rest_obj],"Nil","N/A","N/A","N/A","N/A","N/A","N/A",true) 
    end

    def switchToJSON(rest_obj,branch='@RUBY')
        return switchTo(:json,rest_obj,branch)
    end

    def switchToXML(rest_obj,branch='@RUBY')

        return switchTo(:xml,rest_obj,branch)
    end

    def clearCookies(rest_obj,branch='@RUBY')
        startTiming(rest_obj)
        result_p = @exec_rest_object[rest_obj].clearCookies()
        stopTiming(rest_obj)
        @stack.add(branch,rest_obj,"clearCookies",result_p,@timing[rest_obj],@exec_rest_object[rest_obj].getRestType,"N/A","N/A","N/A","N/A","N/A","N/A",false)
        return result_p
    end

    def clearSessionParameters(rest_obj,branch='@RUBY')
        startTiming(rest_obj)
        result_p = @exec_rest_object[rest_obj].clearSessionParameters()
        stopTiming(rest_obj)
        @stack.add(branch,rest_obj,"clearSessionParameters",result_p,@timing[rest_obj],@exec_rest_object[rest_obj].getRestType,"N/A","N/A","N/A","N/A","N/A","N/A",false)
        return result_p
    end


    def saveSessionParameter(rest_obj,param_name,int_var,branch='@RUBY')
        startTiming(rest_obj)
        result_p = @exec_rest_object[rest_obj].saveSessionParameter(param_name,int_var)
        stopTiming(rest_obj)
        @stack.add(branch,rest_obj,"saveSessionParameter",result_p,@timing[rest_obj],@exec_rest_object[rest_obj].getRestType,"N/A","N/A","N/A","N/A","N/A","N/A",false)
        return result_p    
    end


    def checkAllResult(rest_obj,branch)

        if rest_obj == "null"
            list = @rest_list.each_key.to_a
        else
            list = [ rest_obj ]
        end

        result = true

        list.each do |a_rest_obj|
            startTiming(a_rest_obj)
            if @exec_rest_object.has_key?(a_rest_obj)
                    result_p = @exec_rest_object[a_rest_obj].checkAllResult()
            else
                result_p = false
            end

            result = result & result_p
            stopTiming(a_rest_obj)
            @stack.add(branch,a_rest_obj,"checkAllResult",result_p,@timing[a_rest_obj],"Nil","N/A","N/A",@exec_rest_object[a_rest_obj].getVar('_result',:xml),@exec_rest_object[a_rest_obj].getVar('_result',:json),"N/A","N/A",true)
      end

      return result
    end

#             _            _       
#  _ __  _ __(_)_   ____ _| |_ ___ 
# | '_ \| '__| \ \ / / _` | __/ _ \
# | |_) | |  | |\ V / (_| | ||  __/
# | .__/|_|  |_| \_/ \__,_|\__\___|
# |_|                              
#

    private

    def switchTo(rest_type,rest_obj,branch)

        method = rest_type == :xml ? "switchToXML" : "switchToJSON"

        if rest_obj == "null"
            list = @rest_list.each_key.to_a
        else
            list = [ rest_obj ]
        end

        result = true



        list.each do |a_rest_obj|
            startTiming(a_rest_obj)
            if @exec_rest_object.has_key?(a_rest_obj)
                if rest_type == :xml
                    result_p = @exec_rest_object[a_rest_obj].switchToXML()
                elsif rest_type == :json
                    result_p = @exec_rest_object[a_rest_obj].switchToJSON()
                else
                    result_p = false
                end
            else
                result_p = false
            end

            result = result & result_p
            stopTiming(a_rest_obj)
            @stack.add(branch,a_rest_obj,method,result_p,@timing[a_rest_obj],"Nil","N/A","N/A","N/A","N/A","N/A","N/A",false)
      end

      return result
    end


    def interpreter()

        ## create Restest objects

        @exec_rest_object = Hash.new

        @rest_list.each_key do |rest_obj_name|
            #(test_desc,url,expected_return_code,expected_data,expected_type,expected_info,path,params)

            #$stderr.write("New(#{rest_obj_name}) => #{@rest_list[rest_obj_name][:webservice_type]} / #{@rest_list[rest_obj_name][:webservice_type].class}\n")

            if @rest_list[rest_obj_name][:webservice_type] == :rest || rest_obj_name == "null"

                @exec_rest_object[rest_obj_name] = Restest.new(     rest_obj_name, 
                                                                    { :json => @rest_list[rest_obj_name]['url.json'], :xml => @rest_list[rest_obj_name]['url.xml']},
                                                                    @rest_list[rest_obj_name]['return_code'],
                                                                    @rest_list[rest_obj_name]['expected'],
                                                                    @rest_list[rest_obj_name]['expected_type'],
                                                                    @rest_list[rest_obj_name]['expected_data'],
                                                                    { :json => @rest_list[rest_obj_name]['path.json'] , :xml => @rest_list[rest_obj_name]['path.xml'] },
                                                                    @rest_list[rest_obj_name]['params'],
                                                                    @session_cookies_id,
                                                                    @rest_list[rest_obj_name]['is_expected'],
                                                                    { :json => @rest_list[rest_obj_name]['body.json'] , :xml => @rest_list[rest_obj_name]['body.xml'] },
                                                                    @rest_list[rest_obj_name]['body_parameter_name'],
                                                                    @rest_list[rest_obj_name]['multipart'],
                                                                    @rest_list[rest_obj_name]['body_parameter_content_type'],
                                                                    @rest_list[rest_obj_name]['content_type.json'], @rest_list[rest_obj_name]['content_type.xml']
                                                            )
            end
        end

        return true
    end

    def verbExec(rest_obj,branch,verb)

        unless @exec_rest_object.has_key?(rest_obj)
            setError("'%s' is not defined" % [rest_obj])
            return false
        end

        startTiming(rest_obj)

        result=loopTest(rest_obj,verb)

        stopTiming(rest_obj)

        @stack.add(
                    branch,
                    rest_obj,
                    verb,
                    result,
                    @timing[rest_obj],
                    @exec_rest_object[rest_obj].getRestType,
                    @exec_rest_object[rest_obj].getReturnCode,
                    @exec_rest_object[rest_obj].getExpectedReturnCode,
                    @exec_rest_object[rest_obj].getVar,
                    @exec_rest_object[rest_obj].getExpectedValue,
                    @exec_rest_object[rest_obj].getReturnValue,
                    @rest_list[rest_obj]["is_expected"],
                    true
                    )

        return result  


    end

    def startTiming(rest_obj_id)
        unless @timing.has_key?(rest_obj_id)
             @timing[rest_obj_id] = Hash.new
             @timing[rest_obj_id][:stop] = 0
        end
        @timing[rest_obj_id][:start] = Time.now
    end

    def stopTiming(rest_obj_id)
        unless @timing.has_key?(rest_obj_id)
             @timing[rest_obj_id] = Hash.new
             @timing[rest_obj_id][:start] = 0
        end
        @timing[rest_obj_id][:stop] = Time.now
    end

    def verbose(msg)
        if @verbose
            printf(msg)
        end
    end

    def checkObjectName(objname)

        if objname.match(/^[A-Za-z_][A-Za-z0-9_\.]*/)
            return true
        end

        return false

    end

    def matchPathVar(str)
        if str.match(/^([A-Za-z_][A-Za-z0-9_\.]*)\s*=>\s*(var|path|function\.[^:]+):.*/)
            return true
        else
            return false
        end
    end

    def checkURL(url)
    
        url_to_check = url.gsub(/#\{[^\}]+\}/,'')
    
        begin
            URI.parse(url_to_check)
        rescue
            return false
        end

        unless url.match(/^https?:\/\/.*/)
            return false
        end

        return true
    end

    def _parse(filename=@filename,level=0)

        if(level>100)
            setError("Too many recursive include")
            return false
        end

        @parsed = true
        @parsing_ok = false
        current_cloned=false

        begin
            file = File.open(filename,mode="r")
        rescue
            setError("can not open file %s. %s!" % [filename,$!],file,filename)
            return false
        end

        
        def_detected = false
        current_def = nil
        def_type = nil
        file.each do |a_line|

            a_line.chomp!

            if a_line.match(/^\s*\#/)
                next
            end

            if a_line.match(/^\s*$/)
                next
            end


            #substitue macro_var before all processing
            # @macro_var.each do |a_var,a_value|
            #     subs="\#\{#{a_var}\}"
            #     a_line = a_line.gsub(subs,a_value)

            # end

            macroVarSubs!(a_line)

            if res = a_line.match(/^\s*include\s+\"([^\""]+)\"\s*$/)
                include_file=res[1]
                unless include_file.match(/^\//)
                    include_file = File.dirname(filename)+'/'+include_file
                end

                unless _parse(include_file,level+1)
                    setError("Failed to parse file #{include_file}",file,filename)
                    file.close
                    return false
                end

                next
            end
            
            #~ def function: myregexp1 regexp(3,^ncdjncjdncjdcjd$)
            #~ def function: mysplit1 split(-1,/)
            if res = a_line.match(/^\s*def\s+function:\s+([a-zA-Z_][a-zA-Z_0-9]*)\s+(regexp|split)\((-?[0-9]+),(.*)\)\s*$/)

                unless Restest.addFunction(res[1],res[2],res[3],res[4])
                    setError("def function: failed, #{res[1]} already defined",file,filename)
                    file.close
                    return false
                end
                next
            end

            if res = a_line.match(/^\s*define\s+(\$[^\s]+)\s(.*)$/)
                a_macro_var=res[1]
                a_macro_value=res[2]
                
                if @macro_var_overridden.has_key?(a_macro_var)
                    next # macro_var is set by cli and do not be overridden but can be exist twice
                end

                if @macro_var.has_key?(a_macro_var)
                    setError("Macro var #{a_macro_var} is already defined",file,filename)
                    file.close
                    return false
                end

                @macro_var[a_macro_var] = a_macro_value               

                next
            end

            if res = a_line.match(/^\s*def\s+(rest|soap):\s*(.*)$/)
                ws_type = res[1].to_sym
                def_name_tmp = res[2]

                if def_detected
                    setError("'%s' defined in nested def" % [def_name_tmp],file,filename)
                    file.close
                    return false
                end

                if @rest_list.has_key?(def_name_tmp)
                    setError("'%s' is already defined" % [def_name_tmp],file,filename)
                    file.close
                    return false
                end

                if RESERVED_WORDS.has_key?(def_name_tmp)
                    setError("'%s' is a reserved word" % [def_name_tmp],file,filename)
                    file.close
                    return false
                end

                unless checkObjectName(def_name_tmp)
                    setError("'%s' bad syntax" % [def_name_tmp],file,filename)
                    file.close
                    return false
                end

                def_detected = true
                def_type = :webservice

                current_def = def_name_tmp
                current_cloned=false
                @rest_list[current_def] = Hash.new
                @rest_list[current_def][:webservice_type] = ws_type
                #$stderr.write("#{current_def} => #{@rest_list[current_def][:webservice_type]} // #{@rest_list[current_def][:webservice_type].class}\n")
                next
            end

            if res = a_line.match(/^\s*def\s+branch:\s*(.*)$/)

                if def_detected
                    setError("'%s' defined in nested def" % [res[1]],file,filename)
                    file.close
                    return false
                end

                if @branch_list.has_key?(res[0])
                    setError("'%s' is already defined" % [res[1]],file,filename)
                    file.close
                    return false
                end

                unless checkObjectName(res[1])
                    setError("'%s' bad syntax" % [res[1]],file,filename)
                    file.close
                    return false
                end

                def_detected = true
                def_type = :branch
                current_def = res[1]
                @branch_list[current_def] = Hash.new
                @branch_list[current_def][:config] = Hash.new
                @branch_list[current_def][:action] = Array.new
                next
            end

            if def_detected && def_type == :webservice
                if res = a_line.match(/^\s*([^=\s]+)\s*=(\s|<<)?(.*)$/)
                    param = res[1]
                    data_read_method = res[2]
                    value = res[3]

                    if data_read_method == "<<"
                        if res = value.match(/^\s*(label|file):\/\/(.*)$/)
                            if res[1] == "label"
                                value = readLabel(file,res[2])
                            else
                                file_to_read = res[2]
                                unless file_to_read.match(/^\//)
                                    file_to_read = File.dirname(filename)+'/'+file_to_read
                                end
                                value = readFile(file_to_read)
                            end

                            if value == nil
                                setError("Unable to read value #{res[1]}://#{res[2]}",file,filename)
                                file.close
                                return false
                            end
                        else
                            setError("Syntax error for '%s', expected label://LABEL or file://path_to_file" % [value],file,filename)
                            file.close
                            return false
                        end
                    end

                    
                    if REST_KEYWORDS_SIMPLE.has_key?(param)
                        if @rest_list[current_def].has_key?(param) && ! current_cloned
                            setError("'%s' is already set" % [param],file,filename)
                            file.close
                            return false
                        end

                        if param == 'return_code'
                            @rest_list[current_def][param] = value
                        else
                            if param == "is_expected" || param == "multipart"
                                if (value.to_s =~ /(true|t|yes|y|1)$/i)
                                    @rest_list[current_def][param] =  true
                                elsif (value.to_s =~ /(false|f|no|n|0)$/i)
                                    @rest_list[current_def][param] = false
                                end
                            else    
                                @rest_list[current_def][param] = value
                            end
                        end
                        if param.match(/^url\.(json|xml)/)
                            unless checkURL(value)
                               setError("Invalid URL #{value}",file,filename)
                               file.close
                               return false
                            end
                        end

                        if param == 'expected'
                            unless Restest::EXPECTED_LIST.has_key?(value)
                                setError("Invalid value '#{value}' for expected parameter",file,filename)
                                file.close
                                return false
                            end
                        elsif param == 'expected_type'
                            unless Restest::TYPE_LIST.has_key?(value)
                                setError("Invalid type '#{value}' for expected_type parameter",file,filename)
                                file.close
                                return false
                            end
                           
                        end

                        next
                    elsif REST_KEYWORDS_MULTI.has_key?(param)
                        if ! @rest_list[current_def].has_key?(param) ||  @rest_list[current_def][param] == nil
                            @rest_list[current_def][param] = Hash.new
                        end

                        if keyval = value.match(/^\s*([^=\s]+)\s*=>\s?(.*)/)
                            
                            if @rest_list[current_def][param].has_key?(keyval[1]) && ! current_cloned
                                setError("parameter '%s' already defined" % [keyval[1]],file,filename)
                                file.close
                                return false 
                            else
                                if param.match(/^path\.(json|xml)/)
                                    unless matchPathVar(value)
                                        setError("Syntax error in object '#{current_def}' for path or var interpreter '#{param}' => '#{value}', expected var: or path:")
                                        file.close
                                        return false
                                    end
                                end
                                @rest_list[current_def][param][keyval[1]] = keyval[2]
                                next
                            end

                        else
                            setError("Bad syntax for expected key => value, but have '%s'" % [value],file,filename)
                            file.close
                            return false 
                        end
                    else
                        setError("'%s' parameter does not exist" % [param],file,filename)
                        file.close
                        return false 
                    end
                elsif res = a_line.match(/^\s*([^\(]*)\((.*)\)\s*$/)

                    function = res[1]
                    object = res[2]
                    if function == "clone"
                        unless @rest_list.has_key?(object)
                            setError("Can't clone object '%s', not defined" % [object],file,filename)
                            file.close
                            return false
                        end

                        @rest_list[current_def] = @rest_list[object].clone
                        current_cloned=true
                        next
                    elsif function == "clear"
                        if @rest_list[current_def].has_key?(object)
                            @rest_list[current_def].delete(object)
                        end
                        next
                    else
                        setError("Function '%s', does not exist" % [function],file,filename)
                        file.close
                        return false
                    end
                end

            end

            if def_detected && def_type == :branch
                if res = a_line.match(/^\s*([^\.\()]+).?([^\(]*)\((.*)\)\s*$/)
                    object = nil
                    method = nil
                    parameters = res[3]

                    

                    if res[2] == ""
                        object = "self"
                        method = res[1]
                        #parameters = res[3]
                    else
                        object = res[1]
                        method = res[2]
                        #parameters = res[3]

                    end

                    if method == "sleep"

                        unless parameters.match(/^[0-9]+\.?[0-9]*/)
                            setError("Parameter '%s' for method '%s', is not valid" % [parameters,method],file,filename)
                            file.close
                            return false
                        end
                    else
                        unless checkParameters(parameters)
                            setError("Parameters '%s' for method '%s', are not valid" % [parameters,method],file,filename)
                            file.close
                            return false
                        end

                    end

                    if object == "self"


                        case method

                        when "stopon"
                            if STOPON.has_key?(parameters)
                                if parameters == 'firsterrorforall'
                                    @stoponforall = true
                                else
                                    @branch_list[current_def][:config][:stopon] =  parameters
                                end
                            else
                                setError("Bad parameter '%s' for stopon method in %s expected %s" % [parameters, current_def, STOPON.each_key.to_a.join(',') ],file,filename)
                                file.close
                                return false
                            end
                        when "sleep"
                            @branch_list[current_def][:action] << { :object => "self", :method => "sleep" , :param => parameters}
                        when "switchToXML"
                            @branch_list[current_def][:action] << { :object => "null", :method => "switchToXML" , :param => nil}
                        when "switchToJSON"
                            @branch_list[current_def][:action] << { :object => "null", :method => "switchToJSON" , :param => nil}
                        when "clearCookies"
                            @branch_list[current_def][:action] << { :object => "null", :method => "clearCookies" , :param => nil}
                        when "clearSessionParameters"
                            @branch_list[current_def][:action] << { :object => "null", :method => "clearSessionParameters" , :param => nil}
                        when "checkAllResult"
                            @branch_list[current_def][:action] << { :object => "null", :method => "checkAllResult" , :param => nil}
                        else
                            setError("'%s' is not defined method" % [method],file,filename)
                            file.close
                            return false      
                        end

                        next

                    else
                        unless @rest_list.has_key?(object) || @branch_list.has_key?(object)
                            setError("Object '%s' is not defined" % [object],file,filename)
                            file.close
                            return false  
                        end

                        if REST_METHODS.has_key?(method) || AUTHORIZED_METHODS.has_key?(method)
                            @branch_list[current_def][:action] << { :object => object, :method => method , :param => parameters}
                            next
                        else
                            setError("Method '%s' is not defined for Object %s" % [method,object],file,filename)
                            file.close
                            return false  
                        end
                    end
                end
            end

            if a_line.match(/^\s*end\s*$/)

                current_def = nil
                def_detected = false
                ##closeobject here
                next

            end

            setError("Syntax error :'%s'" % [a_line],file,filename)
            file.close
            return false  

        end


        file.close

        
        # override parameters 



        @overridden_params.each_key do |object|

            unless @rest_list.has_key?(object)
                setError("Object '#{object}' does not exist can't set parameter")
                return false
            end

            @overridden_params[object].each do |a_param,a_value|

                if @rest_list[object]['params'] == nil
                    @rest_list[object]['params'] = Hash.new
                end

                @rest_list[object]['params'][a_param] = a_value

            end
            
        end


        # set default to unset values

        @rest_list.each_key do |rest_object|
            REST_KEYWORDS_MULTI.each do |key,value|
                unless @rest_list[rest_object].has_key?(key)
                    if value[:required]
                        setError("expected parameter(multi) '#{key}' not found")
                        return false
                    else
                        @rest_list[rest_object][key] = value[:default]
                    end
                end
            end
            REST_KEYWORDS_SIMPLE.each do |key,value|
                unless @rest_list[rest_object].has_key?(key)
                    if value[:required]
                        setError("expected parameter(simple) '#{key}' for object #{rest_object} not found")
                        return false
                    else
                        @rest_list[rest_object][key] = value[:default]
                    end

                end
            end

            # check if expected default value or parameters are present e.g. value -> int -> 12

            if  @rest_list[rest_object]['expected'] == nil
                setError("Object '#{rest_object}' has no 'expected' set")
                return false
            end

            if @rest_list[rest_object]['expected'].match(/value|range/)
                if @rest_list[rest_object]['expected_type'] == nil || @rest_list[rest_object]['expected_data'] == nil  
                    setError("Object '#{rest_object}' has no 'expected_type' and/or 'expected_data' set")
                    return false
                end
            elsif @rest_list[rest_object]['expected'].match(/type/)
                if @rest_list[rest_object]['expected_type'] == nil  
                    setError("Object '#{rest_object}' has no 'expected_type' set")
                    return false
                end
            elsif @rest_list[rest_object]['expected'].match(/regexp/)
                if @rest_list[rest_object]['expected_data'] == nil  
                    setError("Object '#{rest_object}' has no 'expected_data' set")
                    return false
                end
            end

        end

        @branch_list.each_key do |branch_key|
            BRANCH_DEFAULT_CONFIG.each do |key,value|
                unless @branch_list[branch_key][:config].has_key?(key)
                    @branch_list[branch_key][:config][key] = value
                end
            end
        end




        @parsing_ok = true

        return true
    end

    def checkParameters(parameters)

        all_params = parameters.split(',')
        all_params.each do |a_param|
            unless checkObjectName(a_param)
                return false
            end
        end
        return true
    end


    def loopTest(object,test_type)
        result_p = false
        for a_retry in 1..@rest_list[object]['loop.retry'].to_i

            case test_type

            when "get"
                result_p = @exec_rest_object[object].get()
            when "post"
                result_p = @exec_rest_object[object].post()
            when "delete"
                result_p = @exec_rest_object[object].delete()
            when "put"
                result_p = @exec_rest_object[object].put()
            end
            if result_p
                break
            end
            sleep(@rest_list[object]['loop.between_retry'].to_f)
        end

        return result_p
    end

    def execute(branch)

        result = true


        unless @branch_list.has_key?(branch)
            setError("Branch '#{branch}' does not exists")
            return false
        end


        faststop=false

        if @branch_list[branch][:config][:stopon] == "firsterror" || @stoponforall
            faststop=true
        end

        if @branch_list.has_key?(branch)
            @branch_list[branch][:action].each do |action|
                #check object_type
                if @rest_list.has_key?(action[:object])
                    case action[:method]
                    #(branch,object,action,return_code,return_value,status)
                    when "get"
                        result_p = get(action[:object],branch)
                        result = result_p && result
                        return false if ! result_p && faststop
                        
                    when "post"
                        result_p=post(action[:object],branch)
                        result = result_p && result
                        return false if ! result_p && faststop

                    when "delete"
                        result_p=delete(action[:object],branch)
                        result = result_p && result
                        return false if ! result_p && faststop

                    when "put"
                        result_p=put(action[:object],branch)
                        result = result_p && result
                        return false if ! result_p && faststop                    

                    when "getVar"
                        int_var,remote_var=action[:param].split(',')

                        result_p=getVar(action[:object],int_var,remote_var,branch)

                        result = result_p && result

                        return false if ! result_p && faststop

                    when "setVarToParam"

                        int_var,param_name = action[:param].split(',')

                        result_p = setVarToParam(action[:object],int_var,param_name,branch)
                        
                        result = result_p && result
                        return false if ! result_p && faststop

                    when "setVarToExpectedData"

                        result_p = setVarToExpectedData(action[:object],action[:param],branch)
                        
                        result = result_p && result
                        return false if ! result_p && faststop

                    when "setBody"
                        startTiming(action[:object])
                        an_object,remote_var = action[:param].split(',')

                        result_p = setBody(action[:object],an_object,remote_var,branch)
                        result = result_p && result

                        return false if ! result_p && faststop

                    when "switchToXML"
                         result_p = switchToXML(action[:object],branch)
                         result = result && result_p
                    when "switchToJSON"

                        result_p = switchToJSON(action[:object],branch)
                        result = result && result_p
                        
                    when "clearCookies"
                        
                        result_p = clearCookies(action[:object],branch)
                        result = result && result_p

                    when "clearSessionParameters"

                         result_p = clearSessionParameters(action[:object],branch)
                         result =  result && result_p

                    when "saveSessionParameter"
                        param_name,int_var = action[:param].split(',')
                        result_p = saveSessionParameter(action[:object],param_name,int_var,branch)
                        result = result && result_p

                    when "checkAllResult"
                        
                        result_p = checkAllResult(action[:object],branch)
                        result = result && result_p

                    else
                    end

                elsif @branch_list.has_key?(action[:object]) || action[:object] == "self"
                    case action[:method]
                    when "run"
                        startTiming(action[:object])
                        result_p = execute(action[:object])
                        result = result_p && result
                        stopTiming(action[:object])
                        @stack.add(branch,action[:object],action[:method],result_p,@timing[action[:object]])
                        return false if ! result_p && faststop
                    when "sleep"
                        startTiming(action[:object])
                        sleep(action[:param].to_f)
                        stopTiming(action[:object])
                        @stack.add(branch,action[:object],action[:method],true,@timing[action[:object]])
                    else
                    end
                else
                    setError("Object '#{action[:object]}'' does not exist")
                    return false
                end
            end
        else
            setError("Branch '#{branch}' does not exist")
            return false
        end


        return result
    end

    def setError(msg,fh=nil,filename=nil)
        
        if fh != nil
            @error << "#{msg} at #{filename} line #{fh.lineno}"
        else
            @error << msg
        end
    end

    def readLabel(fh,label)

        str=""

        re = Regexp.new("^#{label}$")

        fh.each do |a_line|
            if a_line.match(re)
                return str
            end
            macroVarSubs!(a_line)
            str << a_line
        end

        return nil

    end

    def readFile(filename)
        begin
            str=""

            file = File.open(filename,"r")
            file.each do |a_line|
                macroVarSubs!(a_line)
                str << a_line
            end
            file.close
            #printf($stderr,"-%s-",str)
            return str
        rescue => err
            setError("Unable to read file #{$filename} / #{err}")
            return nil
        end
    end

    def macroVarSubs!(a_line)
        replace = VarReplace.new(@macro_var)
        replace.subs!(a_line)
    end
end
