class SavedSearch < ActiveRecord::Base
  serialize :filters, JSON
  belongs_to :team
end
