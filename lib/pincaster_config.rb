class PincasterConfig

  attr_accessor :raw_config

  def initialize(config_hash)
    @raw_config = config_hash
    splat_config
  end

  def splat_config
    @raw_config.each_pair do |key, value|
      self.class.send(:attr_accessor, key.to_sym)
      self.send(key.to_s+"=", value)
    end
  end

end
