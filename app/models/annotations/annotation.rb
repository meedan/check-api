class Annotation
  include AnnotationBase

  before_validation :cant_instantiate_abstract_class

  def load
    self.annotation_type.camelize.constantize.find(self.id)
  end

  def self.all_sorted(order = 'asc', field = 'created_at')
    Annotation.search(query: { match_all: {} }, sort: [{ field => { order: order }}, '_score']).results
  end

  private

  def cant_instantiate_abstract_class
    raise 'You cannot instantiate this abstract class'
  end
end
