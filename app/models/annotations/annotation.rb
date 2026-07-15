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

  def self.load_edge_nodes(edge_nodes)
    edge_nodes
    .group_by { |node| self.annotation_class(node) }
    .flat_map do |klass, nodes|
      records = klass.where(id: nodes.map(&:id)).index_by(&:id)
      nodes.map { |node| records[node.id] }
    end
  end

  def self.annotation_class(node)
    klass = nil
    begin
      klass = node.annotation_type.camelize.constantize
    rescue NameError
      klass = Dynamic
    end
    klass
  end

  def destroy
    dec = self.disable_es_callbacks
    skip_ability = self.skip_check_ability
    a = self.load
    unless a.nil?
      a.disable_es_callbacks = dec
      a.skip_check_ability = skip_ability
      a.destroy
    end
  end

  private

  def cant_instantiate_abstract_class
    raise 'You cannot instantiate this abstract class'
  end
end
