require 'json'
require 'pincaster_layer'

class Pincaster

  @@http_client = HttpClient.new('http','localhost',4269)

  # Pincaster server is still alive?
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

  # returns all known layers
  def self.layers
    JSON.parse(@@http_client.send_request('GET', '/api/1.0/layers/index.json').body)["layers"]
  end

  # returns true if Pincaster already has the given layer
  def self.has_layer?(layer)
    raise "Layer has to be a string" if not layer.is_a?(String)
    self.layers.detect{|l| l["name"] == layer}.nil? ? false : true
  end

  # adds a new layer with name of the given string
  def self.add_layer(layer)
    raise "Layer has to be a string" if not layer.is_a?(String)
    @@http_client.send_request('POST', "/api/1.0/layers/#{layer}.json").code == "200" ? true : false rescue false
  end

  # deletes the layer with the given name
  def self.delete_layer!(layer)
    raise "Layer has to be a string" if not layer.is_a?(String)
    @@http_client.send_request('DELETE', "/api/1.0/layers/#{layer}.json").code == "200" ? true : false rescue false
  end

  # return a layer object for the layer that was searched for
  def self.layer(layer)
    raise "Layer has to be a string" if not layer.is_a?(String)
    PincasterLayer.new(self.layers.select{|l| l["name"] == layer})
  end

end
