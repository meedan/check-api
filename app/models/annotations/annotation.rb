class Annotation
  include AnnotationBase

  before_validation :cant_instantiate_abstract_class

  def load
    self.annotation_type.camelize.constantize.find(self.id)
  end

  private

  def cant_instantiate_abstract_class
    raise 'You cannot instantiate this abstract class'
  end
end
