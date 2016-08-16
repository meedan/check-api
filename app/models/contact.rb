class Contact < ActiveRecord::Base
  attr_accessible
  belongs_to :team
  phony_normalize :phone
  validates :phone, phony_plausible: true

end
