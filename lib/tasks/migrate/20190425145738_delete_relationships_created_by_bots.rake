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
      puts "[#{Time.now}] Resetting counters and re-indexing sources..."
      ProjectMedia.where('sources_count > 0 OR targets_count > 0').update_all({ sources_count: 0, targets_count: 0 })
      Relationship.find_each do |r|
        print '.'
        r.send :increment_counters
        r.send :index_source
      end
      puts
      puts "[#{Time.now}] Done!"
    end
  end
end
