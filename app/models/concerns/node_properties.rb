# Note: looks like we're deviating from Rails expected conventions. Maybe
# reimplement in light of:
#   https://nvisium.com/blog/2015/06/22/using-rails-5-attributes-api-today-in/
module NodeProperties
  def self.included(base)
    @base = base

    base.class_eval do
      # Node properties:
      # * Serialized as JSON
      # * The smart setter set_property(key, value) takes care of duplications, etc.
      serialize :properties, coder: JsonWithIndifferentAccess

      validates :raw_properties, json: { message: 'contains invalid JSON' }
    end
  end

  SERVICE_KEYS = %i[protocol port state product reason name version]
  SERVICE_PROPERTIES = %w[services services_extras]

  # -------------------------------------------- Individual property management
  # Sets a property, storing value as Array when needed
  # and taking care of duplications
  def set_property(key, value)
    if SERVICE_PROPERTIES.include?(key.to_s) # let's get defensive
      raise ArgumentError, 'don\'t use set_property for :services or '\
                           ':services_extras, use set_service instead'
    end

    current_value = self.properties[key]

    # Even though we're serializing JsonWithIndifferentAccess, and the
    # properties can be returned using String or Symbol keys, the
    # :value_is_there variable defined below is depending on Array's #include?
    # and this method wouldn't match two hashes unless they're both
    # #with_indifferent_access
    value = value.with_indifferent_access if value.is_a?(Hash)

    value_is_there = (current_value == value) || (current_value.is_a?(Array) && current_value.include?(value))
    return current_value if value.blank? || value_is_there

    if current_value.blank?
      self.properties[key] = value
    else
      self.properties[key] = [current_value, value].flatten.uniq
    end

    self.properties[key] = self.properties[key].first if self.properties[key].size == 1

    return self.properties[key]
  end

  def has_any_property?
    self.properties.keys.any? { |p| self.properties[p].present? }
  end

  # -------------------------------------------- Individual property management

  # data = a hash of options. must have keys port, protocol, and source (the
  # name of the plugin e.g. 'nmap'.)
  #
  # The following properties, if present, will be saved as information about
  # the services under the `services` key on properties: port, protocol, state,
  # product, reason, name, version.
  #
  # Anything else will be saved under the `services_extras` key
  def set_service(data)
    data = data.symbolize_keys
    port     = data.fetch(:port)
    protocol = data.fetch(:protocol)
    source   = data.fetch(:source)
    data.delete(:source)

    core  = data.slice(*SERVICE_KEYS)
    extra = data.except(*SERVICE_KEYS)

    self.properties[:services] ||= []
    this_service = self.properties[:services].find do |service|
      service[:port] == port && service[:protocol] == protocol
    end

    if this_service.nil?
      self.properties[:services].push(core)
    else
      # the variable 'this_service' is a reference, so updating it like this
      # will update the entry in original properties[:services] array
      this_service.merge!(core)
    end

    if extra.any?
      pp_key = "#{protocol}/#{port}"
      self.properties[:services_extras] ||= {}
      self.properties[:services_extras][pp_key] ||= []
      extra.each do |k, v|
        self.properties[:services_extras][pp_key].push(
          source: source, id: k.to_s, output: v
        )
      end
    end
  end

  # -------------------------------------- :raw_properties accessors for the UI
  def raw_properties
    if self.has_any_property?
      JSON.pretty_generate(self.properties.to_hash)
    elsif @raw_properties
      @raw_properties
    else
      "{\n}"
    end
  end

  # We do this as a two-step operation:
  #   - First we try to detect JSON errors. If none are found, we set the
  #   Node's properties.
  #   - If there is an error, we keep the malformed value (to give the user a
  #   chance of fixing it), but don't assign the Node's properties.
  def raw_properties=(value)
    @raw_properties = JSON::parse(value)
    self.properties = @raw_properties
  rescue JSON::ParserError => exception
    @raw_properties = value
  end
end
