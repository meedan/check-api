class Annotation < ApplicationRecord
  include AnnotationBase

  before_validation :cant_instantiate_abstract_class

  def load
    klass = nil
    begin
      klass = self.annotation_type.camelize.constantize
    rescue NameError
      klass = Dynamic
    end
    klass.where(id: self.id).last
  end

  def destroy
    dec = self.disable_es_callbacks
    skip_ability = self.skip_check_ability
    a = self.load
    a.disable_es_callbacks = dec
    a.skip_check_ability = skip_ability
    a.destroy
  end

  private

  def cant_instantiate_abstract_class
    raise 'You cannot instantiate this abstract class'
  end
end
