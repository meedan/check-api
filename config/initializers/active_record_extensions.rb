module ActiveRecordExtensions
  extend ActiveSupport::Concern

  included do
    include CheckPermissions
    include CheckNotifications::Pusher

    attr_accessor :no_cache, :skip_check_ability, :skip_notifications

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

  def to_slack(text)
    # https://api.slack.com/docs/message-formatting#how_to_escape_characters
    { '&' => '&amp;', '<' => '&lt;', '>' => '&gt;' }.each { |k,v|
      text = text.gsub(k,v)
    }
    text
  end

  def to_slack_url(url, text)
    url.insert(0, "#{CONFIG['checkdesk_client']}/") unless url.start_with? "#{CONFIG['checkdesk_client']}/"
    text = self.to_slack(text)
    text = text.tr("\n", ' ')
    "<#{url}|#{text}>"
  end

  def to_slack_quote(text)
    text = I18n.t(:blank) if text.blank?
    text = self.to_slack(text)
    text.insert(0, "\n") unless text.start_with? "\n"
    text.gsub("\n", "\n>")
  end

  private

  def send_slack_notification
    bot = Bot::Slack.default
    bot.notify_slack(self) unless bot.nil?
  end

end

ActiveRecord::Base.send(:include, ActiveRecordExtensions)
