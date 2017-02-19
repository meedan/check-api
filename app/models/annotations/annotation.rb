class Annotation < ActiveRecord::Base
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
    self.load.destroy
  end

  private

  def cant_instantiate_abstract_class
    raise 'You cannot instantiate this abstract class'
  end
end
