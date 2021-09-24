class RemoveDataFromAccounts < ActiveRecord::Migration[4.2]
  def change
    Account.find_each do |account|
      account.pender_data = account.read_attribute(:data)
      account.set_pender_result_as_annotation
    end

    remove_column :accounts, :data
  end
end
