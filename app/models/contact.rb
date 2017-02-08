class Contact < ActiveRecord::Base
  attr_accessible :team, :location, :phone, :web
  belongs_to :team
  phony_normalize :phone, default_country_code: 'US'
  validates :phone, phony_plausible: true

end
