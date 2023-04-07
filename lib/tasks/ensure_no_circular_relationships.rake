namespace :check do
  desc "Identify and delete circular relationships (i.e. cases where sorted [source_id,target_id] have more than one result)"
  task :ensure_no_circular_relationships do
    batch_size = 10
    offset = 0
    unique_cases = {}
    any_cases = 0
    loop do
      # Query the circular relationships table with a limit and offset
      circular_relationships = Relationship.joins("JOIN relationships AS r2 ON relationships.target_id = r2.source_id AND relationships.source_id = r2.target_id").limit(batch_size).offset(offset)
      # Do something with the circular relationships, e.g. print them to the console
      circular_relationships.each do |relationship|
        any_cases += 1
        key = [relationship.source_id, relationship.target_id].sort
        if unique_cases[key] || key.uniq.count == 1
          # puts relationship.attributes
          relationship.destroy
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
  end
end