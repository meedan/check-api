class Contact < ActiveRecord::Base
  attr_accessible
  belongs_to :team

end
