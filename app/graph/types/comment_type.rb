class CommentType < BaseObject
  include Types::Inclusions::AnnotationBehaviors

  def id
    object.relay_id('comment')
  end

  field :text, GraphQL::Types::String, null: true
end
