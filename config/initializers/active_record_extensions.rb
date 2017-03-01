module ActiveRecordExtensions
  extend ActiveSupport::Concern

  included do
    include CheckdeskPermissions
    include CheckdeskNotifications::Slack
    include CheckdeskNotifications::Pusher

    attr_accessor :no_cache, :skip_check_ability

    before_save :check_ability
    before_destroy :check_destroy_ability, :destroy_annotations_and_versions
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

  def class_name
    self.class.name
  end

  def destroy_annotations_and_versions
    self.versions.destroy_all if self.class_name.constantize.paper_trail.enabled?
    self.annotations.destroy_all if self.respond_to?(:annotations)
  end

end

ActiveRecord::Base.send(:include, ActiveRecordExtensions)
