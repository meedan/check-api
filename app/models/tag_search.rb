class TagSearch < ActiveRecord::Base
  include CheckElasticSearchModel

  attribute :tag, String
end
