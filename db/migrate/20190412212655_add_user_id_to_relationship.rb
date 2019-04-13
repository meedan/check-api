class AddUserIdToRelationship < ActiveRecord::Migration
  def change
    add_column :relationships, :user_id, :integer
    n = Relationship.count
    i = 0
    Relationship.find_each do |r|
      i += 1
      puts "[#{Time.now}] (#{i}/#{n}) Setting user_id for relationship with id #{r.id}"
      uid = r.versions.first&.whodunnit.to_i
      u = User.where(id: uid).last
      r.update_column(:user_id, uid) unless u.nil?
    end
  end
end
