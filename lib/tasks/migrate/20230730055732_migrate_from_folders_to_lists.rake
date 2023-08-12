namespace :check do
  namespace :migrate do
    task fix_tags_with_invalid_data: :environment do
      started = Time.now.to_i
      last_id = Annotation.where(annotation_type: 'tag').last.id
      limit = 500
      offset = 0
      errors = []
      loop do
        print '.'
        query = "SELECT id, data FROM annotations WHERE annotation_type = 'tag' AND id < $1 ORDER BY id LIMIT $2 OFFSET $3"
        result = ActiveRecord::Base.connection.exec_query(query, 'tag query', [last_id, limit, offset]).to_a
        break if result.length == 0
        result.each do |raw|
          begin
            tag = Tag.find(raw['id'])
            tag_text = tag.data['tag']
            if tag_text.class.name == 'TagText'
              print '.'
              errors << raw['id']
              data = { tag: tag_text.id }.with_indifferent_access
              tag.update_columns(data: data)
            end
          rescue Psych::DisallowedClass
            print '.'
            errors << raw['id']
            data = YAML.load(raw['data'])
            tag_text = data['tag']
            new_data = { tag: tag_text.id }.with_indifferent_access
            # execute update query
            Annotation.where(id: raw['id']).update_all(data: new_data)
          end
        end
        offset += limit
      end
      puts "Invalid tags count:: #{errors.count}"
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end

    # Migrate folder to list against all teams or specific one
    # All teams: bundle exec rails check:migrate:migrate_from_folders_to_lists
    # Specific team: bundle exec rails check:migrate:migrate_from_folders_to_lists['team_slug1,team_slug2,...']
    task migrate_from_folders_to_lists: :environment do |_t, args|
      started = Time.now.to_i
      index_alias = CheckElasticSearchModel.get_index_alias
      client = $repository.client
      slugs = args.extras
      condition = {}
      if slugs.blank?
        last_team_id = Rails.cache.read('check:migrate:migrate_from_folders_to_lists:team_id') || 0
        # Collect teams with activity in the last year
        last_year = Time.now - 1.years
        team_ids = ProjectMedia.select('team_id').where('created_at > ?', last_year).group('team_id').map(&:team_id).uniq
        condition = { id: team_ids }
      else
        last_team_id = 0
        condition = { slug: slugs }
      end
      errors = []
      Team.where(condition).where('id > ?', last_team_id).find_each do |team|
        puts "Processing team [#{team.slug}]"
        team_tags = team.tag_texts.map{ |tag| [tag.id.to_s, tag.text] }.to_h
        team.projects.where(is_default: false).find_each do |project|
          puts "Processing folder [#{team.slug} => #{project.title}(#{project.id})]\n"
          # Copy normalize_tag from TagText
          p_title = project.title.strip.gsub(/^#/, '')
          tag_name = project.project_group_id.nil? ? p_title : "(#{project.project_group.title.strip})(#{p_title})"
          # Create TagText if not exists
          tag_text = TagText.where(text: tag_name, team_id: team.id).last
          if tag_text.nil?
            tag_text = TagText.new
            tag_text.text = tag_name
            tag_text.team_id = team.id
            tag_text.save!
            # Add new tag to team_tags array
            team_tags[tag_text.id.to_s] = tag_text.text
          end
          project.project_medias.find_in_batches(:batch_size => 1000) do |pms|
            print '.'
            ids = pms.map(&:id)
            existing_tags = Tag.where(annotated_id: ids, annotated_type: 'ProjectMedia')
            .where("data = ?", { tag: tag_text.id }.with_indifferent_access.to_yaml).map(&:annotated_id)
            # Tag existing items (exclude items with same tag)
            ids = ids - existing_tags
            inserts = []
            ids.each {|pm_id| inserts << { annotated_type: 'ProjectMedia', annotated_id: pm_id, annotation_type: 'tag', data: { tag: tag_text.id } }.with_indifferent_access }
            # Bulk-insert tags
            result = Annotation.import inserts, validate: false, recursive: false, timestamps: true unless inserts.blank?
            # delete cache to enforce creation on first hit
            ids.each{ |pm_id| Rails.cache.delete("check_cached_field:ProjectMedia:#{pm_id.to_i}:tags_as_sentence") }
            # Update ES
            # Collect tags for each ProjectMedia item
            pm_tags = Hash.new {|hash, key| hash[key] = [] }
            Annotation.where(annotation_type: 'tag', annotated_type: 'ProjectMedia', annotated_id: ids).find_each do |tag|
              pm_tags[tag.annotated_id] << { id: tag.id, tag: team_tags[tag.data["tag"].to_s] }
            end
            es_body = []
            pm_tags.each do |pm_id, tags|
              print '.'
              # Set tags_as_sentence cached field
              tags_as_sentence = tags.collect{|item| item[:tag]}.uniq.join(', ')
              Rails.cache.write("check_cached_field:ProjectMedia:#{pm_id.to_i}:tags_as_sentence", tags_as_sentence)
              doc_id = Base64.encode64("ProjectMedia/#{pm_id}")
              fields = { 'tags' => tags, 'tags_as_sentence' => tags_as_sentence.split(', ').size }
              es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
            end
            client.bulk body: es_body unless es_body.blank?
          end
          # Update tags count
          tag_text.update_column(:tags_count, tag_text.calculate_tags_count)
          # Create a list with tag filter
          ss = SavedSearch.new
          ss.team = team
          ss.title = project.title
          ss.filters = { tags: [tag_name] }
          begin ss.save! rescue errors << tag_name end
        end
        Rails.cache.write('check:migrate:migrate_from_folders_to_lists:team_id', team.id)
      end
      puts "Failed to create a list with tags: #{errors.inspect}" unless errors.blank?
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end