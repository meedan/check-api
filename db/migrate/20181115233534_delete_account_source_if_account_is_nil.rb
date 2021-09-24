class DeleteAccountSourceIfAccountIsNil < ActiveRecord::Migration[4.2]
  def change
    AccountSource.find_each do |as|
      as.destroy if as.account.nil?
    end
  end
end
