class DeleteAccountSourceIfAccountIsNil < ActiveRecord::Migration
  def change
    AccountSource.find_each do |as|
      as.destroy if as.account.nil?
    end
  end
end
