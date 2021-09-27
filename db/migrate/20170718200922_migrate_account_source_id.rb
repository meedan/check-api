class MigrateAccountSourceId < ActiveRecord::Migration[4.2]
  def change
    Account.find_each do |account|
      unless account.source_id.nil?
        source = Source.where(id: account.source_id).last
        unless source.nil?
          account.sources << source
        end
      end
    end
    remove_column :accounts, :source_id
  end
end
