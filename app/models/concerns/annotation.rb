module Annotation
  extend ActiveSupport::Concern

  included do
    include CheckdeskElasticSearchModel
    include ActiveModel::Validations

    attribute :type, String
    before_validation :set_type
  end

  private

  def set_type
    self.type = self.class.name.parameterize
  end
end
