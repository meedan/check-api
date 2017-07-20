class AccountSource < ActiveRecord::Base
  belongs_to :source
  belongs_to :account
end
