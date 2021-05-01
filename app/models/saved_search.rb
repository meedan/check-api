class SavedSearch < ActiveRecord::Base
  validates_presence_of :title, :team_id
  
  belongs_to :team
end
