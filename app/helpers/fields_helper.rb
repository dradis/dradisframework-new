module FieldsHelper
  FIELD_VALUES_REGEX = /(\{\{[^}]+\}\})|\|?([^|]+)/

  def parse_field_value_options(values)
    values.scan(FIELD_VALUES_REGEX)
      .flatten
      .compact
      .map(&:strip)
      .reject(&:empty?)
  end
end
