require 'active_support/concern'

module TeamPrivate
  extend ActiveSupport::Concern

  protected

  def get_values_from_entry(entry)
    (entry && entry.respond_to?(:values)) ? entry.values : entry
  end

  private

  def add_user_to_team
    return if self.is_being_copied
    user = User.current
    unless user.nil?
      tu = TeamUser.new
      tu.user = user
      tu.team = self
      tu.role = 'admin'
      tu.skip_check_ability = true
      tu.save!

      user.current_team_id = self.id
      user.save!
    end
  end

  def add_default_bots_to_team
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
    CheckSearch.new(params.to_json, nil, self.id)
  end

  def update_reports_if_labels_changed
    statuses = self.settings.to_h.with_indifferent_access[:media_verification_statuses]
    statuses_were = self.settings_before_last_save.to_h.with_indifferent_access[:media_verification_statuses]
    self.class.delay_for(1.second).update_reports_if_labels_changed(self.id, statuses_were, statuses)
  end

  def update_report_and_tipline_based_on_languages_changed
    languages = self.settings.to_h.with_indifferent_access[:languages]
    languages_were = self.settings_before_last_save.to_h.with_indifferent_access[:languages]
    if languages && languages_were
      diff = languages_were - languages

      update_reports_if_languages_changed(diff)
      update_tipline_workflow_languages(languages, diff)
    end
  end

  def update_reports_if_languages_changed(diff)
    return if diff.blank?
    self.class.delay_for(1.second).update_reports_if_languages_changed(self.id, diff)
  end

  def update_tipline_workflow_languages(languages, diff)
    # the default supported language should be a tipline language workflow, irregardles if the prior default language was deleted or not
    # a deleted supported language should not be a tipline language workflow
    # we should not have a duplicate tipline language workflow for the same language
    tbi = self.team_bot_installations.find_by(user: BotUser.smooch_user)
    return if tbi.blank?

    settings = tbi.settings

    update_tipline_if_default_language_changed(tbi, languages, settings)
    update_tipline_if_language_deleted(tbi, diff, settings)
  end

  def update_tipline_if_language_deleted(tbi, diff, settings)
    return if diff.blank?
    removed_language = diff.first
    return if tbi.nil?

    workflows = settings['smooch_workflows']
    updated_workflows = workflows.reject { |workflow| workflow['smooch_workflow_language'] == removed_language }
    updated_settings = settings.merge('smooch_workflows' => updated_workflows)

    tbi.update(settings: updated_settings)
  end

  def update_tipline_if_default_language_changed(tbi, languages, settings)
    default_language = self.get_language
    workflows = settings['smooch_workflows']

    # Return if the default language is already present in the tipline
    return if workflows.any? { |workflow| workflow['smooch_workflow_language'] == default_language }

    # Add new language workflow if not
    new_workflow = Bot::Smooch.default_settings.first
    new_workflow['smooch_workflow_language'] = default_language
    workflows << new_workflow
    updated_settings = settings.merge('smooch_workflows' => workflows)

    tbi.update(settings: updated_settings)
  end

  def empty_data_structure
    data_structure = MonthlyTeamStatistic.new.formatted_hash
    data_structure["Language"] = self.default_language
    data_structure["Org"] = self.name
    [data_structure]
  end

  def get_dashboard_export_headers(ts, dashboard_type)
    # Get dashboard headers for both types (articles_dashboard & tipline_dashboard) in format { key: value }
    # key(string): header label
    # Value(Hash): { method_name: 'callback that should apply to the method output'}
    # In some cases, the value may be empty ({}) as some methods will populate more than one row.

    # Common header between articles_dashboard and tipline_dashboard
    header = {
      'Articles Sent': { number_of_articles_sent: 'to_i' },
      'Matched Results (Fact-Checks)': { number_of_matched_results_by_article_type: 'values' },
      'Matched Results (Explainers)': {},
    }
    # Hash to include top items as the header label depend on top_items size
    top_items = {}
    # tipline_dashboard columns
    if dashboard_type.to_sym == :tipline_dashboard
      header.merge!({
        'Conversations': { number_of_conversations: 'to_i' },
        'Messages': { number_of_messages: 'to_i' },
        'Conversations (Positive)': { number_of_search_results_by_feedback_type: 'values' },
        'Conversations (Negative)': {}, 'Conversations (No Response)': {},
        'Avg. Response Time': { average_response_time: 'to_i' },
        'Users (Total)': { number_of_total_users: 'to_i' },
        'Users (Unique)': { number_of_unique_users: 'to_i' },
        'Users (Returning)': { number_of_returning_users: 'to_i' },
        'Subscribers': { number_of_subscribers: 'to_i' },
        'Subscribers (New)': { number_of_new_subscribers: 'to_i' },
        'Newsletters (Sent)': { number_of_newsletters_sent: 'to_i' },
        'Newsletters (Delivered)': { number_of_newsletters_delivered: 'to_i' },
        'Media Received (Text)': { number_of_media_received_by_media_type: 'values' },
        'Media Received (Link)': {}, 'Media Received (Audio)': {}, 'Media Received (Image)': {}, 'Media Received (Video)': {},
      })
      top_items = { top_media_tags: 'Top tag', top_requested_media_clusters: 'Top Requested' }
    else
      # article_dashboard columns
      header.merge!({
        'Published Fact-Checks': { number_of_published_fact_checks: 'to_i' },
        'Explainers Created': { number_of_explainers_created: 'to_i' },
        'Fact-Checks Created': { number_of_fact_checks_created: 'to_i' },
      })
      rates = ts.send('number_of_fact_checks_by_rating').keys
      unless rates.blank?
        # Get the first element to fill the label and callback methods as other element will calling with empty callbacks
        f_rate = rates.delete_at(0)
        header.merge!({ "Claim & Fact-Checks (#{f_rate})": { number_of_fact_checks_by_rating: 'values' }})
        rates.each{ |rate| header.merge!({"Claim & Fact-Checks (#{rate})": {}}) }
      end
      top_items = { top_articles_tags: 'Top Article Tags', top_articles_sent: 'Top Fact-Checks Sent' }
    end
    unless top_items.blank?
      top_callback = proc { |output| output.collect{|item| "#{item[:label]} (#{item[:value]})"} }
      # Append Top tags/requested header based on result count
      top_items.each do |method, prefix|
        col_numbers = ts.send(method).size
        if col_numbers > 0
          # Add a first one with method callback
          header.merge!({"#{prefix} (1)": { "#{method}": top_callback } })
          (col_numbers - 1).times do |i|
            # Append other columns with empty method
            header.merge!({"#{prefix} (#{i+2})": {} })
          end
        end
      end
    end
    header
  end
end
