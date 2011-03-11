class PincasterPin

  attr_reader :pin_hash

  def initialize(pin_hash)
    @pin_hash = pin_hash
    splat_pin
  end

  # provides an accessor for every pin value that came back from Pincaster
  def splat_pin
    @pin_hash.each_pair do |key, value|
      self.class.send(:attr_accessor, key.to_sym)
      self.send(key.to_s + "=", value)
    end
  end

  # returns the ActiveRecord:id of this pin's matching ActiveRecord object
  def id
    key
  end
end
