#!/usr/bin/ruby1.9.3

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

require 'sinatra'
require 'json'
require 'rexml/document'
include REXML

set :bind, '127.0.0.1'
set :username,'Bond'
set :password,'007'
set :token,'@LM%$LLKJ196466TGFJJDljcdcd$$!//SZ21'
$counter=0

helpers do
  def admin? ; request.cookies[settings.username] == settings.token ; end
  def protected!(type)
    unless admin?
      if type == :json
        halt [ 401, { :error =>'Not Authorized'}.to_json ]
      else
        halt 401, {'Content-Type' => 'text/xml'}, '<error>Not Authorized</error>'
      end
    end
  end
end

get '/' do
  { :msg => 'Welcome', :test => 'value2' }.to_json
end

post '/json/login' do
  printf($stderr,"POST/JSON/LOGIN:-Login=-%s-/Password=-%s-\n",params['username'],params['password'])
  params.each_key do |key|
    printf($stderr,"POST/JSON/LOGIN:-%s-=-%s-\n",key,params[key])
  end
  if params['username'] == settings.username && params['password'] == settings.password
    response.set_cookie(settings.username,settings.token) 
    { :success => true}.to_json
  else
      halt [ 401, { :error => "Code utilisateur ou mot de passe incorrect"}.to_json ]
  end
end

post '/xml/login' do
  printf($stderr,"POST/XML/LOGIN:-Login=-%s-/Password=-%s-\n",params['username'],params['password'])
  params.each_key do |key|
    printf($stderr,"POST/XML/LOGIN:-%s-=-%s-(%s)\n",key,params[key],params[key].class)
  end
  if params['username'] == settings.username && params['password'] == settings.password
    response.set_cookie(settings.username,settings.token) 
    content_type 'text/xml'
    '<auth success="true"/>'
  else
      halt 401, {'Content-Type' => 'text/xml'}, '<error>Code utilisateur ou mot de passe incorrect</error>'
  end
end


get '/json/login' do
  printf($stderr,"GET/JSON/LOGIN:-Login=-%s-/Password=-%s-\n",params['username'],params['password'])
  params.each_key do |key|
    printf($stderr,"GET/JSON/LOGIN:-%s-=-%s-\n",key,params[key])
  end
  if params['username'] == settings.username && params['password'] == settings.password
    response.set_cookie(settings.username,settings.token) 
    { :success => true}.to_json
  else
      halt [ 401, { :error => "Code utilisateur ou mot de passe incorrect"}.to_json ]
  end
end

get '/xml/login' do
  if params['username'] == settings.username && params['password'] == settings.password
    response.set_cookie(settings.username,settings.token) 
    content_type 'text/xml'
    '<auth success="true"/>'
  else
      halt 401, {'Content-Type' => 'text/xml'}, '<error>Code utilisateur ou mot de passe incorrect</error>'
  end
end

PUBLIC_DATA='Public'
PRIVATE_DATA='Private'

get('/logout') { response.set_cookie(settings.username, false) }

get '/json/public' do
  if params['data'] != ''
    { :msg => params['data']}.to_json
  else
    { :msg => PUBLIC_DATA}.to_json
  end
end

get '/json/private' do
  protected!(:json)
  { :msg => PRIVATE_DATA}.to_json
end

get '/json/int' do
  protected!(:json)
  { :value => 12 }.to_json
end

get '/xml/int' do
  protected!(:json)
  content_type 'text/xml'
  '<value val="12"/>'
end


get '/json/pubint' do
  { :value => 12 }.to_json
end

get '/xml/pubint' do
  content_type 'text/xml'
  '<value val="12"/>'
end


get '/json/pubstr' do
  { :value => "striiiiing" }.to_json
end

get '/xml/pubstr' do
  content_type 'text/xml'
  '<value val="striiiiing"/>'
end



get '/xml/public' do
  content_type 'text/xml'
  '<msg val="'+PUBLIC_DATA+'"/>'
end

get '/xml/private' do
  protected!(:xml)
  content_type 'text/xml'
  '<msg>'+PRIVATE_DATA+'</msg>'
end





get '/json/concat' do
  { :firstname=>"James", :lastname=> "Bond", :codename=>"007"}.to_json
end

get '/xml/concat' do
  content_type 'text/xml'
  '<concat><firstname>James</firstname><lastname>Bond</lastname><codename>007</codename></concat>'
end

get '/json/counter' do
  if $counter >= 5
    { :counter=>true}.to_json
  else
    $counter += 1  
    { :counter=>false}.to_json
  end
end


get '/json/counter_failed' do
  if $counter >= 1000
    { :counter=>true}.to_json
  else
    $counter += 1  
    { :counter=>false}.to_json
  end
end


get '/getid/:rest' do
    case params[:rest]

    when "json"
        printf($stderr,"json\n")
        { 'id' => '1337'}.to_json
         
    when "xml"
        printf($stderr,"xml\n")
        content_type 'text/xml'
        '<response><id>1337</id></response>'

    else
        printf($stderr,"BAD:%s\n",params[:rest])
        halt [ 400, {'Content-Type' => 'text/txt'}, 'WTF' ]
    end
end

get '/loginwparam/:rest' do
    auth_found=false
    if params['id'] == '1337'
        printf($stderr,"Auth OK\n")
        auth_found=true
    end

    case params[:rest]

    when "json"
        printf($stderr,"json\n")
        if auth_found
            { :auth => true}.to_json
        else
            halt [ 401, { :auth => false, :error => "Code utilisateur ou mot de passe incorrect"}.to_json ]
        end

    when "xml"
        printf($stderr,"xml\n")
        if auth_found
            content_type 'text/xml'
            '<response><auth>true</auth></response>'
        else
            halt [ 401, {'Content-Type' => 'text/xml'}, '<response><auth>false</false><error>Code utilisateur ou mot de passe incorrect</error></response>' ]
        end

    else
        printf($stderr,"BAD:%s\n",params[:rest])
        halt [ 400, {'Content-Type' => 'text/txt'}, 'WTF' ]
    end

end

post '/body/json/:id' do

  mydata = request.body.read
  printf($stderr,"JSON(%s): -%s-\n",params[:id],mydata)
  content_type 'text/json'
  JSON.parse(mydata).to_json
end

post '/body/xml/:id' do
  mydata =   request.body.read
  printf($stderr,"XML(%s): -%s-\n",params[:id],mydata)
  content_type 'text/xml'
  mydata

end



get '/array/json' do
  value={ 'value' => ['value1','value2','value3']}
  content_type 'text/json'
  value.to_json
end

get '/array/xml' do
  content_type 'text/xml'
  '<xml><value val="value1"/><value val="value2"/><value val="value3"/></xml>'
end


get '/json/myid' do
  content_type 'text/json'
  { 'id' => "ID2000" }.to_json
end


get '/xml/myid' do
  content_type 'text/xml'
  '<xml><id>ID2000</id></xml>'
end

get '/json/contentmyid' do
  content_type 'text/json'
  { "ID2000" => 12 , "ID3000" => 100 }.to_json
end

get '/xml/contentmyid' do
  content_type 'text/xml'
  '<xml><ID2000>12</ID2000><ID3000>100</ID3000></xml>'
end

get '/json/url' do
    content_type 'text/json'
    { 'value' => 'http://www.example.com/ID2102'}.to_json
end

get '/xml/url' do
    content_type 'text/xml'
    '<xml><value src="http://www.example.com/ID2102"/></xml>'
end

post '/bodyparam/json' do
    printf($stderr,"STARTING POST/JSON/BODYPARAM\n")
    params.each_key do |key|
        printf($stderr,"POST/JSON/BODYPARAM:-%s-=-%s-\n",key,params[key].inspect)
    end
    val1 = params['value1'].to_i
    json = JSON.parse(params['mybody'])
    val2 = json['value'].to_i
    printf($stderr,"POST/JSON/BODYPARAM:-%d-%d-\n",val1,val2)
    content_type 'text/json'
    { "value" => val1 + val2 }.to_json

end

post '/bodyparam/xml' do
    printf($stderr,"STARTING POST/JSON/BODYPARAM\n")
    params.each_key do |key|
        printf($stderr,"POST/JSON/BODYPARAM:-%s-=-%s-\n",key,params[key].inspect)
    end
    val1 = params['value1'].to_i
    xmldoc = Document.new(params['mybody'])
    val2 = XPath.match(xmldoc, '//value/text()')[0].to_s.to_i
    printf($stderr,"POST/JSON/BODYPARAM:-%d-%d-\n",val1,val2)
    content_type 'text/xml'
    "<xml><value>#{val1+val2}</value></xml>"
end

post '/bodyparammultipart/json' do
    printf($stderr,"STARTING POST/JSON/BODYPARAMMULTIPART\n")
    params.each_key do |key|
        printf($stderr,"POST/JSON/BODYPARAMMULTIPART:-%s-=-%s-\n",key,params[key].inspect)
    end
    val1 = params['value1'].to_i
    json = JSON.parse(File.read(params['mybody'][:tempfile]))
    val2 = json['value'].to_i
    printf($stderr,"POST/JSON/BODYPARAM:-%d-%d-\n",val1,val2)
    content_type 'text/json'
    { "value" => val1 + val2 }.to_json

end

post '/bodyparammultipart/xml' do
    printf($stderr,"STARTING POST/JSON/BODYPARAMMULTIPART\n")
    params.each_key do |key|
        printf($stderr,"POST/JSON/BODYPARAMMULTIPART:-%s-=-%s-\n",key,params[key].inspect)
    end
    val1 = params['value1'].to_i
    xmldoc = Document.new(File.read(params['mybody'][:tempfile]))
    val2 = XPath.match(xmldoc, '//value/text()')[0].to_s.to_i
    printf($stderr,"POST/JSON/BODYPARAM:-%d-%d-\n",val1,val2)
    content_type 'text/xml'
    "<xml><value>#{val1+val2}</value></xml>"
end


post '/bodyparammultipartct/json' do
    printf($stderr,"STARTING POST/JSON/BODYPARAMMULTIPARTCT\n")
    params.each_key do |key|
        printf($stderr,"POST/JSON/BODYPARAMMULTIPARTCT:-%s-=-%s-\n",key,params[key].inspect)
    end
    val1 = params['value1'].to_i
    json = JSON.parse(File.read(params['mybody'][:tempfile]))
    val2 = json['value_json'].to_i
    printf($stderr,"POST/JSON/BODYPARAM:-%d-%d-\n",val1,val2)
    content_type 'text/json'
    { "value" => val1 + val2 }.to_json

end

post '/bodyparammultipartct/xml' do
    printf($stderr,"STARTING POST/JSON/BODYPARAMMULTIPARTCT\n")
    params.each_key do |key|
        printf($stderr,"POST/JSON/BODYPARAMMULTIPARTCT:-%s-=-%s-\n",key,params[key].inspect)
    end
    val1 = params['value1'].to_i
    json = JSON.parse(File.read(params['mybody'][:tempfile]))
    val2 = json['value_xml'].to_i
    printf($stderr,"POST/JSON/BODYPARAM:-%d-%d-\n",val1,val2)
    content_type 'text/xml'
    "<xml><value>#{val1+val2}</value></xml>"
end

post '/multi' do
    puts request.body.read
    params.each_key do |key|
        printf($stderr,"POST/JSON/MULTI:-%s-=-%s-\n",key,params[key].inspect)
    end
    
    content_type 'text/json'
    { 'value' => 'http://www.example.com/ID2102'}.to_json
end


get '/value/json' do
    content_type 'text/json'
    { "value" => 1234 }.to_json
end

get '/multivalue/json' do
    content_type 'text/json'
    { "value" => "1234,1234,1234" }.to_json
end

get '/echo/json/:value' do
    value = params[:value].to_i
    content_type 'text/json'
    { "value" => value }.to_json
end

get '/value/xml' do
    content_type 'text/xml'
    "<xml><value>1234</value></xml>"
end

get '/multivalue/xml' do
    content_type 'text/xml'
    "<xml><value>1234,1234,1234</value></xml>"
end


get '/echo/xml/:value' do
    value = params[:value]
    content_type 'text/xml'
    "<xml><value>#{value}</value></xml>"
end
