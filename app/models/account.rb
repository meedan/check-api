class Account < ActiveRecord::Base
  belongs_to :user
  belongs_to :source
  has_many :media
end
