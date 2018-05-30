class Team < ActiveRecord::Base

  include ValidationsHelper
  include DestroyLater
  include TeamValidations
  include TeamAssociations
  include TeamPrivate
  include TeamDuplication

  attr_accessor :affected_ids, :is_being_copied

  mount_uploader :logo, ImageUploader

  before_validation :normalize_slug, on: :create

  after_create :add_user_to_team
  after_update :archive_or_restore_projects_if_needed, :clear_embeds_caches_if_needed
  after_destroy :reset_current_team

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

  def projects_count
    self.projects.count
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

  def owners(role)
    self.users.where('team_users.role' => role)
  end

  def recent_projects
    self.projects.order('title ASC')
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

  def recipients(requestor, role='owner')
    owners = self.owners(role)
    recipients = []
    if !owners.empty? && !owners.include?(requestor)
      recipients = owners.map(&:email).reject{ |m| m.blank? }
    end
    recipients
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
      c[:options] = options if options
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
        t[:options] ||= []
        t[:projects] = [] if t[:projects].nil?
        t[:mapping] = {"type"=>"text", "match"=>"", "prefix"=>""} if t[:mapping].nil? || t[:mapping].blank?
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

  def hide_names_in_embeds=(hide)
    self.send(:set_hide_names_in_embeds, hide)
  end

  def self.archive_or_restore_projects_if_needed(archived, team_id)
    Project.where({ team_id: team_id }).update_all({ archived: archived })
    Source.where({ team_id: team_id }).update_all({ archived: archived })
    ProjectMedia.joins(:project).where({ 'projects.team_id' => team_id }).update_all({ archived: archived })
  end

  def self.empty_trash(team_id)
    Team.find(team_id).trash.destroy_all
  end

  def empty_trash=(confirm)
    if confirm
      ability = Ability.new
      if ability.can?(:destroy, :trash)
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
    filename = field.match(/_statuses$/) ? 'statuses' : field
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

  def custom_permissions(ability = nil)
    perms = {}
    ability ||= Ability.new
    perms["empty Trash"] = ability.can?(:destroy, :trash)
    perms
  end

  protected

  def get_values_from_entry(entry)
    (entry && entry.respond_to?(:values)) ? entry.values : entry
  end

  # private
  #
  # Please add private methods to app/models/concerns/team_private.rb
end
