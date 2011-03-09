class Pincaster

  def self.is_alive?
    HttpClient.new('http', 'localhost', 4269).send_request('GET', '/api/1.0/system/ping.json').code == "200" ? true : false rescue false
  end

end
