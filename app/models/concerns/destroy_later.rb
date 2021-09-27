require 'active_support/concern'

module DestroyLater
  extend ActiveSupport::Concern

  def destroy_later(ability = nil)
    ability ||= Ability.new
    if ability.can?(:destroy, self)
      self.before_destroy_later if self.respond_to?(:before_destroy_later)
      self.class.delay.destroy_instance(self.id)
    else
      raise I18n.t(:permission_error, default: "Sorry, you are not allowed to do this")
    end
  end

  module ClassMethods
    def destroy_instance(instance_id)
      self.find(instance_id).destroy!
    end
  end
end
