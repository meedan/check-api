class RemoveDataFromAccounts < ActiveRecord::Migration
  def change
    pender = Bot.where(name: 'Pender').last
    Account.find_each do |account|
      em = Embed.new
      em.embed = account.data
      em.annotated = account
      em.annotator = pender unless pender.nil?
      em.save!
    end
    remove_column :accounts, :data
  end
end
