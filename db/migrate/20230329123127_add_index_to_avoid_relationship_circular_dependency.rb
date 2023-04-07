class AddIndexToAvoidRelationshipCircularDependency < ActiveRecord::Migration[5.2]
  def change
    # Ensure we don't have any circular relationships before creating the index
    # Copied from lib/tasks/ensure_no_circular_relationships.rake
    batch_size = 10
    offset = 0
    unique_cases = {}
    any_cases = 0
    loop do
      # Query the circular relationships table with a limit and offset
      circular_relationships = Relationship.joins('JOIN relationships AS r2 ON relationships.target_id = r2.source_id AND relationships.source_id = r2.target_id').limit(batch_size).offset(offset)
      # Do something with the circular relationships, e.g. print them to the console
      circular_relationships.each do |relationship|
        any_cases += 1
        key = [relationship.source_id, relationship.target_id].sort
        if unique_cases[key] || key.uniq.count == 1
          puts "Deleting relationship ##{relationship.id} between source #{relationship.source_id} and target #{relationship.target_id}"
          relationship.delete
        else
          # Otherwise, add the key to the hash table and keep the current relationship
          unique_cases[key] = true
        end
      end
      # Break the loop if no more records are found
      break if circular_relationships.empty?
      # Increment the offset for the next batch
      offset += batch_size
    end

    execute 'CREATE UNIQUE INDEX ON relationships (LEAST(source_id, target_id), GREATEST(source_id, target_id))'
  end
end
