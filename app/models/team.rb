class Team < ActiveRecord::Base
  has_many :teamUsers
  has_many :users, :through => :teamUsers
end
