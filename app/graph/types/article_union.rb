class ArticleUnion < BaseUnion
  description 'A union type of all article types we can handle'
  possible_types(
    ExplainerType,
  )
end
