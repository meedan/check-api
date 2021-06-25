class AddIndexToAccounts < ActiveRecord::Migration[4.2]
  def change
    #add_column :accounts, :url, :string
    # remove duplicate URLs
    a = Account.all.group_by { |x| x.url }
    a.each do |key, value|
      value.each_with_index do |row, index|
        unless value.length == 1
          if index == value.length - 1
            row.destroy
          end
        end
      end
    end
    add_index :accounts, :url, unique: true
  end
end
