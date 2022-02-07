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
      tu.role = 'admin'
      tu.save!

      user.current_team_id = self.id
      user.save!
    end
  end

  def add_default_bots_to_team
    return if self.is_being_copied
    BotUser.where(default: true).map do |bot_user|
      bot_user.install_to!(self) if bot_user.get_approved
    end
  end

  def normalize_slug
    return if self.slug.blank?
    self.slug = self.slug.downcase
  end

  def archive_or_restore_projects_if_needed
    Team.delay.archive_or_restore_projects_if_needed(self.archived, self.id) if self.saved_change_to_archived?
  end

  def reset_current_team
    User.where(current_team_id: self.id).each{ |user| user.update_columns(current_team_id: nil) }
  end

  def delete_created_bots
    self.team_bots_created.map(&:destroy!)
  end

  def create_team_partition
    if ApplicationRecord.connection.schema_exists?('versions_partitions')
      ApplicationRecord.connection_pool.with_connection do
        partition = "\"versions_partitions\".\"p#{self.id}\""
        ApplicationRecord.connection.execute("CREATE TABLE #{partition} (CHECK(team_id = #{self.id})) INHERITS (versions)")
        ApplicationRecord.connection.execute("CREATE INDEX version_field_p#{self.id} ON #{partition} (version_field_name(event_type, object_after))")
        ApplicationRecord.connection.execute("CREATE INDEX version_annotation_type_p#{self.id} ON #{partition} (version_annotation_type(event_type, object_after))")
        [[:item_type, :item_id], [:event], [:whodunnit], [:event_type], [:team_id], [:associated_type, :associated_id]].each do |columns|
          ApplicationRecord.connection.add_index(partition, columns, name: "version_#{columns.join('_')}_p#{self.id}")
        end
      end
    end
  end

  def anonymize_sources_and_accounts
    Source.where(team_id: self.id).update_all(team_id: nil)
    Account.where(team_id: self.id).update_all(team_id: nil)
  end

  def delete_team_partition
    ApplicationRecord.connection.execute("DROP TABLE \"versions_partitions\".\"p#{self.id}\"") if ApplicationRecord.connection.schema_exists?('versions_partitions')
  end

  def set_default_language
    self.set_language 'en'
    self.set_languages ['en']
  end

  def set_default_fieldsets
    fieldsets = [
      {
        identifier: 'tasks',
        singular: 'task',
        plural: 'tasks'
      }.with_indifferent_access,
      {
        identifier: 'metadata',
        singular: 'metadata',
        plural: 'metadata'
      }.with_indifferent_access
    ]
    self.set_fieldsets fieldsets
  end

  def check_search_filter(params = {})
    params.merge!({ 'parent' => { 'type' => 'team', 'slug' => self.slug }})
    CheckSearch.new(params.to_json)
  end

  def update_reports_if_labels_changed
    statuses = self.settings.to_h.with_indifferent_access[:media_verification_statuses]
    statuses_were = self.settings_before_last_save.to_h.with_indifferent_access[:media_verification_statuses]
    self.class.delay_for(1.second).update_reports_if_labels_changed(self.id, statuses_were, statuses)
  end

  def create_default_folder
    return if self.is_being_copied
    p = Project.new
    p.team_id = self.id
    p.title = 'Unnamed folder (default)'
    p.skip_check_ability = true
    p.is_default = true
    p.save!
  end

  def remove_is_default_project_flag
    # Call this method before destory team to delete all related projects
    # as admin not allowed to delete the default project
    self.default_folder.update_columns(is_default: false)
  end
end
