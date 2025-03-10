class AddAuthorToArticles < ActiveRecord::Migration[6.1]
  def change
    add_reference :fact_checks, :author, index: true
    add_reference :explainers, :author, index: true
    add_reference :claim_descriptions, :author, index: true
  end
end
