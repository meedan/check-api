class AddMissingUniqueIndexes < ActiveRecord::Migration
  def change
  	# fix existing duplicates 
    fix_duplicate(ProjectSource, [:project_id, :source_id])
    fix_duplicate(AccountSource, [:account_id, :source_id])
    fix_duplicate(ClaimSource, [:media_id, :source_id])
    fix_duplicate(ProjectMedia, [:project_id, :media_id])
    # add uniqe indexes
  	add_index :project_sources, [:project_id, :source_id], unique: true
  	add_index :account_sources, [:account_id, :source_id], unique: true
  	add_index :claim_sources, [:media_id, :source_id], unique: true
  	add_index :project_medias, [:project_id, :media_id], unique: true
  end

  def fix_duplicate(type, columns)
  	type.select(columns).group(columns).having('count(*) > 1').each do |i|
  		conditions = {}
  		columns.each{|c| conditions.merge!({ c => i[c] })}
  		items = type.where(conditions).to_a
  		f = items.shift
  		ids = items.map(&:id)
  		Annotation.where(annotated_type: type.to_s, annotated_id: ids).update_all(annotated_id: f.id)
  		type.where(id: ids).destroy_all
  	end
  end
end
