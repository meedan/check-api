namespace :check do
  namespace :migrate do
    task delete_relationships_created_by_bots: :environment do
      n = Relationship.joins(:user).where(['users.type = ?', 'BotUser']).count
      print "[#{Time.now}] Deleting #{n} relationships created by authenticated bots... "
      Relationship.joins(:user).delete_all(['users.type = ?', 'BotUser'])
      puts "Done!"
      n = Relationship.where(user_id: nil).count
      while n > 0
        id = Relationship.where(user_id: nil).limit(1000).order('id ASC').last.id
        print "[#{Time.now}] Deleting 1000/#{n} relationships created by bots... "
        Relationship.where(user_id: nil).where(['relationships.id <= ?', id]).delete_all
        n = Relationship.where(user_id: nil).count
        puts "done, #{n} remaining"
      end
      n = Relationship.joins(:user).where("users.type != 'BotUser' OR users.type IS NULL").count
      puts "[#{Time.now}] Done. Now we have #{Relationship.count} relationships, where #{n} were created by humans."
    end
  end
end
