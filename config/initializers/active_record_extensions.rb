module ActiveRecordExtensions
  extend ActiveSupport::Concern

  included do
    include CheckPermissions
    include CheckNotifications::Pusher
    include CheckSettings

    attr_accessor :no_cache, :skip_check_ability, :skip_notifications, :disable_es_callbacks, :client_mutation_id, :skip_clear_cache

    before_save :check_ability
    before_destroy :check_destroy_ability, :destroy_annotations_and_versions
    validate :cant_mutate_if_inactive
    # after_find :check_read_ability
  end

  module ClassMethods
    def permissioned(team = nil)
      klass = self.to_s.gsub(/::ActiveRecord.*$/, '')
      all_params = RequestStore.store[:graphql_connection_params] || {}
      user = User.current || User.new
      team ||= (Team.current || Team.new)
      params = all_params["#{user.id}:#{team.id}"] ||= {}
      query = all
      if params[klass]
        params = params[klass].clone
        joins = params.delete(:joins)
        query = query.joins(joins) if joins
        query = query.rewhere(params)
      end
      query
    end
  end

  # Used to migrate data from CD2 to this
  def image_callback(value)
    if CONFIG['migrate_checkdesk_images']
      uri = URI.parse(value)
      result = Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') { |http| http.get(uri.path) }
      if result.code.to_i == 200
        file_name = File.basename(uri.path)
        f_extn = File.extname  file_name
        f_name = File.basename file_name, f_extn
        file = Tempfile.new([f_name, f_extn])
        file.binmode # note that our tempfile must be in binary mode
        file.write open(value).read
        file.rewind
        file
      end
    end
  end

  def user_callback(value)
    user = User.where('lower(email) = ?', value.downcase).last unless value.blank?
    user.nil? ? nil : user.id
  end

  def dbid
    self.id
  end

  def is_annotation?
    false
  end

  def class_name
    self.class.name
  end

  def destroy_annotations_and_versions
    Version.from_partition(Version.get_team_id_from_item_type(self.class_name, self)).where(item_type: self.class_name, item_id: self.id.to_s).destroy_all if self.class_name.constantize.paper_trail.enabled?
    self.annotations.destroy_all if self.respond_to?(:annotations)
  end

  def sent_to_slack
    @sent_to_slack
  end

  def sent_to_slack=(bool)
    @sent_to_slack = bool
  end

  def is_archived?
    self.respond_to?(:archived) && self.archived_was
  end

  def graphql_id
    Base64.encode64("#{self.class_name}/#{self.id}")
  end

  def send_slack_notification
    return if (self.respond_to?(:is_being_copied) && self.is_being_copied) || RequestStore.store[:skip_notifications]
    bot = Bot::Slack.default
    bot.notify_slack(self) unless bot.nil?
  end

  def destroy_es_items(es_type, type='destroy_doc_nested', obj=nil)
    return if self.disable_es_callbacks || RequestStore.store[:disable_es_callbacks]
    options = {es_type: es_type, type: type}
    options[:obj] = obj unless obj.nil?
    ElasticSearchWorker.perform_in(1.second, YAML::dump(self), YAML::dump(options), type)
  end

  def parent_class_name
    self.is_annotation? ? 'Annotation' : self.class.name
  end

  def cant_mutate_if_inactive
    if self.respond_to?(:inactive) && self.client_mutation_id && self.inactive
      raise I18n.t(:cant_mutate_inactive_object)
    end
  end
end

ActiveRecord::Base.send(:include, ActiveRecordExtensions)
