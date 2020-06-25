class Team < ActiveRecord::Base
  after_create :create_team_partition, :add_user_to_team

  before_destroy :delete_created_bots

  include ValidationsHelper
  include DestroyLater
  include TeamValidations
  include TeamAssociations
  include TeamPrivate
  include TeamDuplication
  include TeamImport
  include TeamRules

  attr_accessor :affected_ids, :is_being_copied

  mount_uploader :logo, ImageUploader

  before_validation :normalize_slug, on: :create

  after_find do |team|
    if User.current
      Team.current ||= team
      Ability.new(User.current, team)
    end
  end
  after_update :archive_or_restore_projects_if_needed
  before_destroy :destroy_versions
  after_destroy :reset_current_team

  validate :languages_format, unless: proc { |t| t.settings.nil? }

  check_settings

  def logo_callback(value, _mapping_ids = nil)
    image_callback(value)
  end

  def avatar
    custom = begin self.logo.file.public_url rescue nil end
    default = CONFIG['checkdesk_base_url'] + self.logo.url
    custom || default
  end

  def url
    url = self.contacts.map(&:web).select{ |w| !w.blank? }.first
    url || CONFIG['checkdesk_client'] + '/' + self.slug
  end

  def members_count
    self.team_users.where(status: 'member').permissioned(self).count
  end

  def projects_count
    self.projects.permissioned.count
  end

  def as_json(_options = {})
    {
      dbid: self.id,
      id: self.team_graphql_id,
      avatar: self.avatar,
      name: self.name,
      projects: self.recent_projects,
      slug: self.slug
    }
  end

  def owners(role, statuses = TeamUser.status_types)
    self.users.where({'team_users.role': role, 'team_users.status': statuses})
  end

  def recent_projects
    self.projects.order('title ASC')
  end

  def team_graphql_id
    Base64.encode64("Team/#{self.id}")
  end

  # FIXME Source should be using concern HasImage
  # which automatically adds a member attribute `file`
  # which is used by GraphqlCrudOperations
  def file=(file)
    self.logo = file if file.respond_to?(:content_type)
  end

  # FIXME should be using concern HasImage
  # which already include this method
  def should_generate_thumbnail?
    true
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

  def report=(report_settings)
    settings = report_settings.is_a?(String) ? JSON.parse(report_settings) : report_settings
    self.send(:set_report, settings)
  end

  def team_user
    self.team_users.where(user_id: User.current.id).last unless User.current.nil?
  end

  def add_auto_task=(task)
    TeamTask.create! task.merge({ team_id: self.id })
  end

  def remove_auto_task=(task_label)
    TeamTask.where({ team_id: self.id, label: task_label }).map(&:destroy!)
  end

  def set_team_tasks=(list)
    list.each do |task|
      self.add_auto_task = task
    end
  end

  def rules=(rules)
    self.send(:set_rules, JSON.parse(rules))
  end

  def search_id
    CheckSearch.id({ 'parent' => { 'type' => 'team', 'slug' => self.slug } })
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
        self.trash.update_all(inactive: true)
        Team.delay_for(5.seconds).empty_trash(self.id)
      else
        raise I18n.t(:permission_error, "Sorry, you are not allowed to do this")
      end
    end
  end

  def trash
    ProjectMedia.where({ team_id: self.id, archived: true, sources_count: 0 })
  end

  def trash_size
    {
      project_media: self.trash_count,
      annotation: self.trash.sum(:cached_annotations_count)
    }
  end

  def trash_count
    self.trash.count
  end

  def medias_count
    ProjectMedia.where({ team_id: self.id, archived: false, sources_count: 0 }).count
  end

  def check_search_team
    CheckSearch.new({ 'parent' => { 'type' => 'team', 'slug' => self.slug } }.to_json)
  end

  def search
    self.check_search_team
  end

  def check_search_trash
    CheckSearch.new({ 'archived' => 1, 'parent' => { 'type' => 'team', 'slug' => self.slug } }.to_json)
  end

  def public_team
    self
  end

  def rails_admin_json_schema(field)
    statuses_schema = Team.custom_statuses_schema.clone
    statuses_schema[:properties][:statuses][:items][:properties][:locales].delete(:patternProperties)
    properties = {}
    self.get_languages.to_a.each do |locale|
      properties[locale] = {
        type: 'object',
        required: ['label', 'description'],
        properties: {
          label: { type: 'string', title: "Label (#{CheckCldr.language_code_to_name(locale)})" },
          description: { type: 'string', title: "Description (#{CheckCldr.language_code_to_name(locale)})" }
        }
      }
    end
    statuses_schema[:properties][:statuses][:items][:properties][:locales][:properties] = properties
    field =~ /statuses/ ? statuses_schema : {}
  end

  def public_team_id
    Base64.encode64("PublicTeam/#{self.id}")
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
    perms["invite Members"] = ability.can?(:invite_members, self)
    perms["restore ProjectMedia"] = ability.can?(:restore, ProjectMedia.new(team_id: self.id, archived: true))
    perms["update ProjectMedia"] = ability.can?(:update, ProjectMedia.new(team_id: self.id))
    perms
  end

  def permissions_info
    YAML.load(ERB.new(File.read("#{Rails.root}/config/permission_info.yml")).result)
  end

  def invited_mails(team=nil)
    team ||= Team.current
    TeamUser.where(team_id: team.id, status: 'invited').where.not(invitation_token: nil).map(&:invitation_email) unless team.nil?
  end

  def dynamic_search_fields_json_schema
    annotation_types = Annotation
                       .group('annotations.annotation_type')
                       .joins("INNER JOIN project_medias pm ON annotations.annotated_type = 'ProjectMedia' AND pm.id = annotations.annotated_id")
                       .where('pm.team_id' => self.id).count.keys
    properties = {
      sort: { type: 'object', properties: {} }
    }
    annotation_types.each do |type|
      method = "field_search_json_schema_type_#{type}"
      if Dynamic.respond_to?(method)
        schema = Dynamic.send(method, self)
        [schema].flatten.each { |subschema| properties[subschema[:id] || type] = subschema }
      end
      # Uncomment to allow sorting by a dynamic field (was used by deadline field)
      # method = "field_sort_json_schema_type_#{type}"
      # if Dynamic.respond_to?(method)
      #   sort = Dynamic.send(method, self)
      #   properties[:sort][:properties][sort[:id]] = { type: 'array', title: sort[:label], items: { type: 'string', enum: [sort[:asc_label], sort[:desc_label]] } } if sort
      # end
    end
    { type: 'object', properties: properties }
  end

  def get_report_design_image_template
    self.settings[:report_design_image_template] || self.settings['report_design_image_template'] || File.read(File.join(Rails.root, 'public', 'report-design-default-image-template.html'))
  end

  protected

  def get_values_from_entry(entry)
    (entry && entry.respond_to?(:values)) ? entry.values : entry
  end

  # private
  #
  # Please add private methods to app/models/concerns/team_private.rb
end
