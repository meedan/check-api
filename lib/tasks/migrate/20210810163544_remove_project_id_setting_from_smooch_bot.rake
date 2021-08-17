namespace :check do
  namespace :migrate do
    task relate_smooch_user_to_team: :environment do
      started = Time.now.to_i
      Team.find_each do |team|
        team.projects.find_in_batches(:batch_size => 2500) do |ps|
          print '.'
          ids = ps.map(&:id)
          Annotation.where(
            annotation_type: 'smooch_user', annotated_type: 'Project', annotated_id: ids
          ).update_all(annotated_type: 'Team', annotated_id: team.id)
        end
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
