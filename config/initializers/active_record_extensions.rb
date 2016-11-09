module ActiveRecordExtensions
  extend ActiveSupport::Concern

  included do
    include CheckdeskPermissions
    include CheckdeskNotifications::Slack
    include CheckdeskNotifications::Pusher

    attr_accessor :current_user, :context_team, :origin, :no_cache

    before_save :check_ability
    before_destroy :check_destroy_ability
    # after_find :check_read_ability
  end

  # Used to migrate data from CD2 to this
  def image_callback(value)
    unless value.blank?
      uri = URI.parse(value)
      result = Net::HTTP.start(uri.host, uri.port) { |http| http.get(uri.path) }
      if result.code.to_i < 400
        file = Tempfile.new
        file.binmode # note that our tempfile must be in binary mode
        file.write open(value).read
        file.rewind
        file
      end
    end
  end

  def user_callback(value)
    user = User.where(email: value).last
    user.nil? ? nil : user.id
  end

  def dbid
    self.id
  end

  def is_annotation?
    false
  end
end

ActiveRecord::Base.send(:include, ActiveRecordExtensions)
