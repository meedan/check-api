class FactCheckType < DefaultObject
  description "FactCheck type"

  implements NodeIdentification.interface

  field :dbid, Integer, null: true
  field :title, String, null: true
  field :summary, String, null: true
  field :url, String, null: true
  field :language, String, null: true
  field :user, UserType, null: true
  field :claim_description, ClaimDescriptionType, null: true
end
