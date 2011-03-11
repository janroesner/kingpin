class PincasterLayer

  attr_reader :layer_hash

  def initialize(layer_array)
    @layer_hash = layer_array.first
    splat_layer
  end

  # provides an accessor for every pin value that came back from Pincaster
  def splat_layer
    @layer_hash.each_pair do |key, value|
      self.class.send(:attr_accessor, key.to_sym)
      self.send(key.to_s + "=", value)
    end
  end

end
