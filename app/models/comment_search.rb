class CommentSearch < ActiveRecord::Base

  include CheckElasticSearchModel

  attribute :text, String

end
