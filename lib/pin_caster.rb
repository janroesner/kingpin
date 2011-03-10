class Pincaster

  @@http_client = HttpClient.new('http','localhost',4269)

  # Pincaster server is stil alive?
  def self.is_alive?
    @@http_client.send_request('GET', '/api/1.0/system/ping.json').code == "200" ? true : false rescue false
  end

  # shutdown Pincaster server immediately
  def self.shutdown!
    begin
      @@http_client.send_request('POST', '/api/1.0/system/shutdown.json')
    rescue Exception => e
      case e.message
      when "end of file reached"
        return true
      else
        return false
      end
    end
  end

end
