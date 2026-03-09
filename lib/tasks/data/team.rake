namespace :check do
  namespace :team do
    desc 'Delete all team tags'
    # bundle exec rails check:team:delete_tags[slug-1,slug-2,...,slug-N]
    task delete_tags: :environment do |_t, params|
      slugs = params.to_a
      Team.where(slug: slugs).find_each do |team|
        count = team.tag_texts.count
        puts "Deleting tags [#{count}] for team #{team.slug}"
        team.tag_texts.in_batches(of: 500) do |batch|
          print '.'
          batch.destroy_all
        end
      end
    end
    # bundle exec rails check:team:activate[slug-1,slug-2,...,slug-N]
    task activate: :environment do |_t, params|
      slugs = params.to_a
      Team.where(slug: slugs).find_each do |team|
        team.inactive = true
        team.save!
      end
    end
    # bundle exec rails check:team:deactivate[slug-1,slug-2,...,slug-N]
    task deactivate: :environment do |_t, params|
      slugs = params.to_a
      Team.where(slug: slugs).find_each do |team|
        team.inactive = false
        team.save!
      end
    end
    # bundle exec rails check:team:list_teams_with_number_of_members[x]
    desc 'List all teams with members less than or equal X'
    task list_teams_with_number_of_members: :environment do |_t, number|
      number = number.to_a.first.to_i
      output = []
      TeamUser.select('team_id, count(team_id) as m_count, teams.slug as slug')
      .joins(:team)
      .where(type: nil).group('team_id, slug')
      .having("count(team_id) <= ?", number).each do |tu|
        print '.'
        output << { team_id: tu.team_id, slug: tu.slug, members: tu.m_count }
      end
      puts "\nTeams with members count \n"
      pp output
    end
    # bundle exec rails check:team:list_inactive_teams[x]
    desc 'List all teams with no activities since X months ago'
    task list_inactive_teams: :environment do |_t, number|
      number = number.to_a.first.to_i
      date = Time.now - number.months
      output = []
      Team.find_each do |team|
        print '.'
        logs = Version.from_partition(team.id).where('created_at > ?', date).count
        output << { team_id: team.id, slug: team.slug } if logs == 0
      end
      puts "\n Teams list \n"
      pp output
    end
    # bundle exec rails check:team:list_teams_with_number_of_members[x]
    desc 'Delete all teams with members less than or equal X'
    task delete_teams_with_number_of_members: :environment do |_t, number|
      number = number.to_a.first.to_i
      output = []
      TeamUser.select('team_id, count(team_id) as m_count, teams.slug as slug')
      .joins(:team)
      .where(type: nil).group('team_id, slug')
      .having("count(team_id) <= ?", number).each do |tu|
        print '.'
        team = Team.find_by_id tu.team_id
        unless team.nil?
          output << { team_id: team.id, slug: team.slug, members: tu.m_count }
          team.destroy!
        end
      end
      puts "\nDeleted teams \n"
      pp output
    end
    # bundle exec rails check:team:list_inactive_teams[x]
    # desc 'Delete cached/ES for all teams with no activities since X months ago'
    task delete_teams_cached_and_es_values: :environment do |_t, number|
      number = number.to_a.first.to_i
      date = Time.now - number.months
      output = []
      Team.find_each do |team|
        puts "\nProcessing team: #{team.slug}\n"
        logs = Version.from_partition(team.id).where('created_at > ?', date).count
        if logs == 0
          output << { team_id: team.id, slug: team.slug }
          # Delete cached and ES values
          # 1) Cached value for Team role permissions
          puts "\nDelete cache for team roles\n"
          %w(admin editor collaborator authenticated super_admin).each do |role|
            print '.'
            cache_key = "team_permissions_#{team.private.to_i}_#{role}_role_20251027174300"
            Rails.cache.delete(cache_key)
          end
          # 2) ProjectMedias cached and ES
          puts "\nDelete cache and ES documents for ProjectMedia items\n"
          team.project_medias.find_in_batches(:batch_size => 500) do |items|
            items.each do |pm|
              print '.'
              # fields
              pm.clear_cached_fields
              # Tasks
              Rails.cache.delete("project_media:annotated_by:#{pm.id}")
              # Delete ES doc
              doc_id = Base64.encode64("ProjectMedia/#{pm.id}")
              $repository.delete(doc_id)
            end
            # Smooch data
            puts "\nDelete cache for smooch_data annotations\n"
            pm_ids = items.pluck(:id)
            Annotation.where(annotation_type: "smooch", annotated_type: 'ProjectMedia', annotated_id: pm_ids)
            .find_in_batches(:batch_size => 500) do |annotations|
              a_ids = annotations.pluck(:id)
              DynamicAnnotation::Field.where(annotation_id: a_ids, field_name: 'smooch_data').find_each do |f|
                print '.'
                data = JSON.parse(f.value)
                uid = data['authorId']
                Rails.cache.delete("smooch:user_language:#{uid}")
                Rails.cache.delete("smooch:user_language:#{team.id}:#{uid}:confirmed")
                Rails.cache.delete("smooch:last_message_from_user:#{uid}")
                Rails.cache.delete("smooch_resource_waiting_for_user_input:#{uid}")
                Rails.cache.delete('smooch:original:' + data['_id'])
              end
            end
          end
          # 3) Source cached values
          puts "\nDelete cache for Source\n"
          team.sources.find_in_batches(:batch_size => 500) do |sources|
            sources.each do |s|
              print '.'
              Rails.cache.delete("source_overridden_cache_#{s.id}")
            end
          end
          # 4) TiplineNewsletter cached values
          puts "\nDelete cache for TiplineNewsletter\n"
          team.tipline_newsletters.find_in_batches(:batch_size => 500) do |newsletters|
            newsletters.each do |nl|
              print '.'
              Rails.cache.delete(nl.content_hash_key)
            end
          end
          # 5) smoochUser cached values
          puts "\nDelete cache for smoochUser\n"
          Annotation.where(annotation_type: "smooch_user", annotated_type: 'Team', annotated_id: team.id)
          .find_in_batches(:batch_size => 500) do |annotations|
            a_ids = annotations.pluck(:id)
            DynamicAnnotation::Field.where(annotation_id: a_ids, field_name: 'smooch_user_id').find_each do |f|
              print '.'
              uid = f.value
              ["smooch:bundle:#{uid}", "smooch:last_accepted_terms:#{uid}", "smooch:banned:#{uid}"].each { |key| Rails.cache.delete(key) }
            end
          end
          # 6) Fetch cached values
          puts "\nDelete cache for Fetch items\n"
          fetch = BotUser.fetch_user
          team.project_medias.where(user_id: fetch.id).find_in_batches(:batch_size => 500) do |items|
            pm_ids = items.pluck(:id)
            Annotation.where(annotation_type: "verification_status", annotated_type: 'ProjectMedia', annotated_id: pm_ids)
            .find_in_batches(:batch_size => 500) do |annotations|
              a_ids = annotations.pluck(:id)
              DynamicAnnotation::Field.where(annotation_id: a_ids, field_name: 'external_id').find_each do |f|
                print '.'
                id, team_id = f.value.split(':')
                Rails.cache.delete("fetch:claim_review_imported:#{team_id}:#{id}")
              end
            end
          end
        end
      end
      puts "\n Teams list \n"
      pp output
    end
  end
end