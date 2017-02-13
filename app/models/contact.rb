class Contact < ActiveRecord::Base
  belongs_to :team
  phony_normalize :phone, default_country_code: 'US'
  validates :phone, phony_plausible: true

end
