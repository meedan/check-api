class ReindexRelationships < ActiveRecord::Migration
  def change
    RequestStore.store[:skip_notifications] = true
    RequestStore.store[:skip_rules] = true
    total = Relationship.count
    i = 0
    Relationship.order('id ASC').find_each do |relationship|
      i += 1
      print "Updating relationship #{i}/#{total} (ID #{relationship.id})... "
      relationship.updated_at = Time.now
      begin
        relationship.save!
        puts "Updated!"
      rescue Exception => e
        puts "Error: #{e.message}"
      end
    end
    RequestStore.store[:skip_notifications] = false
    RequestStore.store[:skip_rules] = false
  end
end
