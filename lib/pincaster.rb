require 'json'
require 'yaml'
require 'pincaster_layer'
require 'pincaster_pin'
require 'pincaster_config'

class Pincaster

  # returns an existing http client properly configured or creates a new one once
  def self.client
    @@http_client ||= HttpClient.new(self.config.protocol, self.config.host, self.config.port, self.config.namespace)
  end

  # Pincaster server is still alive?
  def self.is_alive?
    self.client.send_request('GET', '/system/ping.json').code == "200" ? true : false rescue false
  end

  # shutdown Pincaster server immediately
  def self.shutdown!
    begin
      self.client.send_request('POST', '/system/shutdown.json')
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
    JSON.parse(self.client.send_request('GET', '/layers/index.json').body)["layers"]
  end

  # returns true if Pincaster already has the given layer
  def self.has_layer?(layer)
    raise "Layer has to be a string" if not layer.is_a?(String)
    self.layers.detect{|l| l["name"] == layer}.nil? ? false : true rescue false
  end

  # adds a new layer with name of the given string
  def self.add_layer(layer)
    raise "Layer has to be a string" if not layer.is_a?(String)
    self.client.send_request('POST', "/layers/#{layer}.json").code == "200" ? true : false rescue false
  end

  # deletes the layer with the given name
  def self.delete_layer!(layer)
    raise "Layer has to be a string" if not layer.is_a?(String)
    self.client.send_request('DELETE', "/layers/#{layer}.json").code == "200" ? true : false rescue false
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
    self.client.send_request('PUT',
                               "/records/#{record.class.to_s}/#{record.id}.json",
                               nil,
                               nil,
                               {:_loc => "#{record.pin_lat},#{record.pin_lng}"}).code == "200" ? true : false
  end

  # returns a pin object for the given ActiveRecord object
  def self.get_record(record)
    PincasterPin.new(JSON.parse(self.client.send_request('GET', "/records/#{record.class.to_s}/#{record.id}.json").body)) rescue nil
  end

  # deletes the Pincaster record for the given ActiveRecord object
  def self.delete_record(record)
    self.client.send_request('DELETE', "/records/#{record.class.to_s}/#{record.id}.json").code == "200" ? true : false
  end

  # returns all pins nearby given record, maximum radius meters away, returns limit number of pins
  def self.nearby(record, radius, limit)
    limit ||= 2000
    raise "Given #{record.class.to_s} has not lng or lat." if record.pin_lng.nil? or record.pin_lat.nil?
    self.client.send_request('GET',
                               "/search/#{record.class.to_s}/nearby/#{record.pin_lat.to_s},#{record.pin_lng.to_s}.json",
                               nil,
                               nil,
                               {:radius => radius.to_s, :limit => limit}).body
  end

  # loads local config, or users one if he provided any
  def self.load_config
    begin
      config = YAML.load_file(Rails.root.to_s + "/config/kingpin.yml")
    rescue
      config = YAML.load_file(File.dirname(__FILE__).to_s + "/../config/kingpin.yml")
    end
    PincasterConfig.new(config)
  end

  # returns config
  def self.config
    @@config ||= self.load_config
  end

end
