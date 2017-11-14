module ActiveRecordExtensions
  extend ActiveSupport::Concern

  included do
    include CheckPermissions
    include CheckNotifications::Pusher
    include CheckSettings

    attr_accessor :no_cache, :skip_check_ability, :skip_notifications, :disable_es_callbacks, :client_mutation_id

    before_save :check_ability
    before_destroy :check_destroy_ability, :destroy_annotations_and_versions
    # after_find :check_read_ability
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
    self.versions.destroy_all if self.class_name.constantize.paper_trail.enabled?
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

  private

  def send_slack_notification
    bot = Bot::Slack.default
    bot.notify_slack(self) unless bot.nil?
  end
end

ActiveRecord::Base.send(:include, ActiveRecordExtensions)
