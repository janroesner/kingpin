class HttpClient

  require 'net/http'
  require "cgi"
  require "benchmark"

  def initialize(protocol, host, port, namespace=nil)
    @http = Net::HTTP.new(host, port)
    @protocol = protocol
    @host = host
    @port = port
    @namespace = namespace
  end

  def send_request(method, resource, headers=nil, data=nil, params=nil)
    return self.send(method.to_s.downcase, headers, resource, data, params)
  end

  protected

  # sends GET request and returns response
  def get(headers, resource, data, params)
    request = Net::HTTP::Get.new(build_uri(resource, params).request_uri, headers)
    @http.request(request)
  end

  # sends PUT request and returns response
  def put(headers, resource, data, params)
    request = Net::HTTP::Put.new(resource_path(resource), headers)
    request.body = params.nil? ? data.to_json : params.to_query
    @http.request(request)
  end

  # sends POST request and returns response
  def post(headers, resource, data, params)
    request = Net::HTTP::Post.new(resource_path(resource), headers)
    request.body = params.nil? ? data.to_json : params.to_query
    @http.request(request)
  end

  # sends DELETE request and returns response
  def delete(headers, resource, data, params)
    request = Net::HTTP::Delete.new(resource_path(resource), headers)
    @http.request(request)
  end

  # redefines the resource path including the namespace
  def resource_path(resource)
    @namespace.nil? ? resource : "/" + @namespace + resource
  end

  # rebuild a uri in details, so that another protocol, host, port and GET params can be specified, after Net::HTTP was created
  def build_uri(resource, params=nil)
    uri = URI.parse(@protocol + "://" + @host + ((@port.nil? || @port != "80") ? ":#{@port}" : ""))
    uri.scheme = @protocol
    uri.host = @host
    uri.port = @port
    uri.query = params.collect{ |k,v| "#{k}=#{CGI::escape(v.to_s)}" }.reverse.join('&') if not params.nil?
    uri.path = resource_path(resource)
    uri
  end
end
