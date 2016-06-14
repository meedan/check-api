class Project < ActiveRecord::Base
  belongs_to :user
  has_many :media
  has_many :projectSources
  has_many :sources , :through => :projectSources
end
