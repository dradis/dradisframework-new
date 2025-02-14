class JsonWithIndifferentAccess
  def self.dump(obj)
    JSON.dump(obj)
  end

  def self.load(str)
    HashWithIndifferentAccess.new(JSON.load(str))
  end
end
