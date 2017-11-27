class Team < ActiveRecord::Base

  include ValidationsHelper
  include NotifyEmbedSystem
  include DestroyLater
  include TeamValidations
  include TeamAssociations
  include TeamPrivate

  attr_accessor :affected_ids

  mount_uploader :logo, ImageUploader

  before_validation :normalize_slug, on: :create

  after_create :add_user_to_team
  after_update :archive_or_restore_projects_if_needed, :clear_embeds_caches_if_needed

  check_settings

  def logo_callback(value, _mapping_ids = nil)
    image_callback(value)
  end

  def avatar
    CONFIG['checkdesk_base_url'] + self.logo.url
  end

  def members_count
    self.users.count
  end

  def as_json(_options = {})
    {
      dbid: self.id,
      id: Base64.encode64("Team/#{self.id}"),
      avatar: self.avatar,
      name: self.name,
      projects: self.recent_projects,
      slug: self.slug
    }
  end

  def owners
    self.users.where('team_users.role' => 'owner')
  end

  def recent_projects
    self.projects.order('id DESC')
  end

  # FIXME Source should be using concern HasImage
  # which automatically adds a member attribute `file`
  # which is used by GraphqlCrudOperations
  def file=(file)
    self.logo = file
  end

  def contact=(info)
    contact = self.contacts.first || Contact.new
    info = JSON.parse(info)
    contact.web = info['web']
    contact.phone = info['phone']
    contact.location = info['location']
    contact.team = self
    contact.save!
  end

  def verification_statuses(type)
    statuses = self.send("get_#{type}_verification_statuses") || Status.core_verification_statuses(type)
    statuses.to_json
  end

  def recipients(requestor)
    owners = self.owners
    recipients = []
    if !owners.empty? && !owners.include?(requestor)
      recipients = owners.map(&:email).reject{ |m| m.blank? }
    end
    recipients
  end

  def media_verification_statuses=(statuses)
    set_verification_statuses('media', statuses)
  end

  def media_verification_statuses
    statuses = self.get_media_verification_statuses
    unless statuses.blank?
      statuses['statuses'] = [] if statuses['statuses'].nil?
      statuses['statuses'].each { |s| s['style'].delete_if {|key, _value| key.to_sym != :color } if s['style'] }
    end
    statuses
  end

  def source_verification_statuses=(statuses)
    set_verification_statuses('source', statuses)
  end

  def slack_notifications_enabled=(enabled)
    self.send(:set_slack_notifications_enabled, enabled)
  end

  def slack_webhook=(webhook)
    self.send(:set_slack_webhook, webhook)
  end

  def slack_channel=(channel)
    self.send(:set_slack_channel, channel)
  end

  def team_user
    self.team_users.where(user_id: User.current.id).last unless User.current.nil?
  end

  def checklist=(checklist)
    checklist = get_values_from_entry(checklist)
    checklist.each_with_index do |c, index|
      c = c.with_indifferent_access
      options = get_values_from_entry(c[:options])
      c[:options] = options.to_json if options && !options.kind_of?(String)
      projects = get_values_from_entry(c[:projects])
      c[:projects] = projects.map(&:to_i) if projects
      c[:label].blank? ?  checklist.delete_at(index) : checklist[index] = c
    end
    self.send(:set_checklist, checklist)
  end

  def checklist
    tasks = self.get_checklist
    unless tasks.blank?
      tasks.map do |t|
        t[:options] = JSON.parse(t[:options]) if t[:options]
        t[:projects] = [] if t[:projects].nil?
      end
    end
    tasks
  end

  def add_auto_task=(task)
    checklist = self.get_checklist || []
    checklist << task.to_h
    self.checklist = checklist
  end

  def remove_auto_task=(task_label)
    checklist = self.get_checklist || []
    self.checklist = checklist.reject{ |t| t['label'] == task_label || t[:label] == task_label }
  end

  def search_id
    CheckSearch.id({ 'parent' => { 'type' => 'team', 'slug' => self.slug } })
  end

  def suggested_tags=(tags)
    self.send(:set_suggested_tags, tags)
  end

  def keep_enabled=(enabled)
    self.send(:set_keep_enabled, enabled)
  end

  def hide_names_in_embeds=(hide)
    self.send(:set_hide_names_in_embeds, hide)
  end

  def notify_destroyed?
    false
  end

  def notify_created?
    true
  end
  alias notify_updated? notify_created?

  def notify_embed_system_created_object
    { slug: self.slug }
  end

  def notify_embed_system_updated_object
    self.as_json
  end

  def notify_embed_system_payload(event, object)
    { project: object, condition: event, timestamp: Time.now.to_i, token: CONFIG['bridge_reader_token'] }.to_json
  end

  def notification_uri(event)
    slug = (event == 'created') ? 'check-api' : self.slug
    URI.parse(URI.encode([CONFIG['bridge_reader_url_private'], 'medias', 'notify', slug].join('/')))
  end

  def self.archive_or_restore_projects_if_needed(archived, team_id)
    Project.where({ team_id: team_id }).update_all({ archived: archived })
    Source.joins(:team_sources).where({ 'team_sources.team_id' => team_id }).update_all({ archived: archived })
    ProjectMedia.joins(:project).where({ 'projects.team_id' => team_id }).update_all({ archived: archived })
  end

  def self.empty_trash(team_id)
    Team.find(team_id).trash.destroy_all
  end

  def empty_trash=(confirm)
    if confirm
      ability = Ability.new
      if ability.can?(:update, self)
        self.affected_ids = self.trash.all.map(&:graphql_id)
        Team.delay.empty_trash(self.id)
      else
        raise I18n.t(:permission_error, "Sorry, you are not allowed to do this")
      end
    end
  end

  def trash
    ProjectMedia.joins(:project).where({ 'projects.team_id' => self.id, 'project_medias.archived' => true })
  end

  def trash_size
    {
      project_media: self.trash.count,
      annotation: self.trash.sum(:cached_annotations_count)
    }
  end

  def check_search_team
    CheckSearch.new({ 'parent' => { 'type' => 'team', 'slug' => self.slug } }.to_json)
  end

  def public_team
    self
  end

  def json_schema_url(field)
    filename = ['media_verification_statuses', 'source_verification_statuses'].include?(field) ? 'statuses' : field
    URI.join(CONFIG['checkdesk_base_url'], "/#{filename}.json")
  end

  def public_team_id
    Base64.encode64("PublicTeam/#{self.id}")
  end

  def self.clear_embeds_caches_if_needed(id)
    pids = Team.find(id).project_ids
    ProjectMedia.where(project_id: pids).find_each do |pm|
      ProjectMedia.clear_caches(pm.id)
    end
  end

  def self.slug_from_name(name)
    name.parameterize.underscore.dasherize.ljust(4, '-')
  end

  def self.current
    RequestStore.store[:team]
  end

  def self.current=(team)
    RequestStore.store[:team] = team
  end

  def self.slug_from_url(url)
    # Use extract to solve cases that URL inside [] {} () ...
    url = URI.extract(url)[0]
    URI(url).path.split('/')[1]
  end

  protected

  def set_verification_statuses(type, statuses)
    statuses = statuses.with_indifferent_access
    statuses[:statuses] = [] if statuses[:statuses].nil?

    if statuses[:statuses]
      statuses[:statuses] = get_values_from_entry(statuses[:statuses])
      statuses[:statuses].delete_if { |s| s[:id].blank? && s[:label].blank? }
      statuses[:statuses].each  { |s| set_status_color(s) }
    end
    statuses.delete_if { |_k, v| v.blank? }
    unless statuses.keys.map(&:to_sym) == [:label]
      self.send("set_#{type}_verification_statuses", statuses)
    end
  end

  def get_values_from_entry(entry)
    (entry && entry.respond_to?(:values)) ? entry.values : entry
  end

  def set_status_color(status)
    if status[:style] && status[:style].is_a?(Hash)
      color = status[:style][:color]
      status[:style][:backgroundColor] = color
      status[:style][:borderColor] = color
    end
  end

  # private
  #
  # Please add private methods to app/models/concerns/team_private.rb 
end
