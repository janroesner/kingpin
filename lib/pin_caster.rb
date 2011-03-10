require 'json'
require 'pincaster_layer'
require 'pincaster_pin'

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
    self.layers.detect{|l| l["name"] == layer}.nil? ? false : true rescue false
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

  # adds a new record as well as creates a layer for it if the latter does not exist already
  def self.add_record(record)
    raise "Can't add a record without geocoordinates lng, lat" if record.pin_lng.nil? or record.pin_lat.nil?
    Pincaster.add_layer(record.class.to_s) if not Pincaster.has_layer?(record.class.to_s)
    @@http_client.send_request('PUT',
                               "/api/1.0/records/#{record.class.to_s}/#{record.id}.json",
                               nil,
                               nil,
                               {:_loc => "#{record.pin_lat},#{record.pin_lng}"}).code == "200" ? true : false
  end

  # returns a pin object for the given ActiveRecord object
  def self.get_record(record)
    PincasterPin.new(JSON.parse(@@http_client.send_request('GET', "/api/1.0/records/#{record.class.to_s}/#{record.id}.json").body)) rescue nil
  end

  # deletes the Pincaster record for the given ActiveRecord object
  def self.delete_record(record)
    @@http_client.send_request('DELETE', "/api/1.0/records/#{record.class.to_s}/#{record.id}.json").code == "200" ? true : false
  end

  def self.nearby(record, radius, limit=200)
    raise "Given #{record.class.to_s} has not lng or lat." if record.pin_lng.nil? or record.pin_lat.nil?
    @@http_client.send_request('GET',
                               "/api/1.0/search/#{record.class.to_s}/nearby/#{record.pin_lat.to_s},#{record.pin_lng.to_s}.json",
                               nil,
                               nil,
                               {:radius => radius.to_s, :overflow => true})
  end

end
