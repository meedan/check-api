class TagTextType < DefaultObject
  description "Tag text type"

  implements NodeIdentification.interface

  field :dbid, Integer, null: true
  field :text, String, null: true
  field :tags_count, Integer, null: true
end
