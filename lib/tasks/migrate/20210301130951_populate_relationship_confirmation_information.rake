namespace :check do
  namespace :migrate do
    task populate_relationship_confirmation_information: :environment do
      old_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = nil
      started = Time.now.to_i
      errors = 0
      total = Relationship.confirmed.count
      i = 0
      Relationship.confirmed.find_in_batches(batch_size: 3000) do |rs|
        i += 1
        puts "#{i * 3000} / #{total}"
        rs.each do |r|
          begin
            v = Version.from_partition(r.target.team_id).where(item_type: 'Relationship', item_id: r.id.to_s).where("object_changes LIKE '%suggested_sibling%confirmed_sibling%'").last
            if v.nil?
              puts "Not a confirmation"
            else
              r.update_columns(confirmed_by: v.user.id, confirmed_at: v.created_at)
              puts "Confirmed by: #{v.user.name}"
            end
          rescue Exception => e
            puts "Error: #{e.message}"
            errors += 1
          end
        end
        puts "[#{Time.now}] Done for batch ##{i}"
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes. Errors: #{errors}"
      ActiveRecord::Base.logger = old_logger
    end
  end
end
