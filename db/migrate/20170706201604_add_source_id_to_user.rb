class AddSourceIdToUser < ActiveRecord::Migration
  def change
    add_reference :users, :source, index: true, foreign_key: true
    # TODO migrate existing data
  end
end
