require 'active_support/concern'

module HasJsonSchema
  extend ActiveSupport::Concern

  included do
    validate :json_schema_is_valid
  end

  private

  def json_schema_is_valid
    if self.json_schema_enabled? && !self.json_schema.blank?
      metaschema = JSON::Validator.validator_for_name('draft4').metaschema
      errors.add(:json_schema, 'must be a valid JSON Schema') unless JSON::Validator.validate(metaschema, self.json_schema)
    end
  end
end
