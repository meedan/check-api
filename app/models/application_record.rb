class ApplicationRecord < ActiveRecord::Base
  include ActiveRecordExtensions

  self.abstract_class = true
end
