require 'active_support/concern'

module TeamPrivate
  extend ActiveSupport::Concern

  private

  def add_user_to_team
    return if self.is_being_copied
    user = User.current
    unless user.nil?
      tu = TeamUser.new
      tu.user = user
      tu.team = self
      tu.role = 'owner'
      tu.save!

      user.current_team_id = self.id
      user.save!
    end
  end

  def normalize_slug
    return if self.slug.blank?
    self.slug = self.slug.downcase
  end

  def archive_or_restore_projects_if_needed
    Team.delay.archive_or_restore_projects_if_needed(self.archived, self.id) if self.archived_changed?
  end

  def reset_current_team
    User.where(current_team_id: self.id).each{ |user| user.update_columns(current_team_id: nil) }
  end

  def delete_created_bots
    self.team_bots_created.map(&:destroy!)
  end

  def set_default_max_number_of_members
    self.set_max_number_of_members 5
  end

  def create_team_partition
    if ActiveRecord::Base.connection.schema_exists?('versions_partitions')
      ActiveRecord::Base.connection_pool.with_connection do
        partition = "\"versions_partitions\".\"p#{self.id}\""
        ActiveRecord::Base.connection.execute("CREATE TABLE #{partition} (CHECK(team_id = #{self.id})) INHERITS (versions)")
        ActiveRecord::Base.connection.execute("CREATE INDEX version_field_p#{self.id} ON #{partition} (version_field_name(event_type, object_after))")
        ActiveRecord::Base.connection.execute("CREATE INDEX version_annotation_type_p#{self.id} ON #{partition} (version_annotation_type(event_type, object_after))")
        [[:item_type, :item_id], [:event], [:whodunnit], [:event_type], [:team_id], [:associated_type, :associated_id]].each do |columns|
          ActiveRecord::Base.connection.add_index(partition, columns, name: "version_#{columns.join('_')}_p#{self.id}")
        end
      end
    end
  end

  def destroy_versions
    Version.from_partition(self.id).where(team_id: self.id).destroy_all
  end
end
