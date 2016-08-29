module ActiveRecordExtensions
  extend ActiveSupport::Concern

  included do
    attr_accessor :current_user
    before_save :check_ability
    before_destroy :check_destroy_ability
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

  private

  def check_ability
   unless self.current_user.nil?
      ability = Ability.new(self.current_user)
      op = self.new_record? ? :create : :update
      raise "No permission to #{op} #{self.class}" unless ability.can?(op, self)
    end
  end

  def check_destroy_ability
    unless self.current_user.nil?
      ability = Ability.new(self.current_user)
      raise "No permission to delete #{self.class}" unless ability.can?(:destroy, self)
    end
  end

end

ActiveRecord::Base.send(:include, ActiveRecordExtensions)
