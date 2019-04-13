namespace :check do
  namespace :migrate do
    task add_user_id_to_relationship: :environment do
      last = PaperTrail::Version.last
      rel = PaperTrail::Version.where(item_type: 'Relationship').where('id < ?', last)
      n = rel.count
      i = 0
      rel.find_each do |v|
        i += 1
        puts "[#{Time.now}] (#{i}/#{n}) Migrating relationship #{v.item_id}"
        r = v.item
        next if r.nil?
        r.update_column(:user_id, v.whodunnit.to_i)
      end
    end
  end
end
