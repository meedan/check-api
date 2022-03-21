namespace :check do
  namespace :migrate do
    task fix_visual_card_for_import_items: :environment do
      started = Time.now.to_i
      # Get latest team id
      last_team_id = Rails.cache.read('check:migrate:fix_visual_card_for_import_items:team_id') || 0
      fetch_user = BotUser.find_by_login('fetch')
      Team.where('id > ?', last_team_id).find_each do |team|
        puts "Processing team [#{team.slug}]"
        team.project_medias.where(user_id: fetch_user.id).joins(:media).where('medias.type' => 'Blank')
        .find_in_batches(:batch_size => 2500) do |pms|
          ids = pms.map(&:id)
          Dynamic.where(annotated_id: ids, annotated_type: 'ProjectMedia', annotation_type: 'report_design')
          .find_in_batches(:batch_size => 2500) do |annotations|
            items = []
            annotations.each do |annotation|
              data = annotation['data']
              if data['options'][0]['use_visual_card']
                print '.'
                annotation['data']['options'][0]['use_visual_card'] = false
                items << annotation
              end
              # Import items with existing ids to make update
              Dynamic.import(items, recursive: false, validate: false, on_duplicate_key_update: [:data])
            end
          end
        end
        # log last team id
        Rails.cache.write('check:migrate:fix_visual_card_for_import_items:team_id', team.id)
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end