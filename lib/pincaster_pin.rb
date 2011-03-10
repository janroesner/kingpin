class PincasterPin

  attr_accessor :pin_hash

  def initialize(pin_hash)
    @pin_hash = pin_hash
  end

  # returns the ActiveRecord:id of this pin's matching ActiveRecord object
  def id
    @pin_hash["key"]
  end
end
