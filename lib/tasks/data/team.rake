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
        Team.activate(team.id, true)
      end
    end
    # bundle exec rails check:team:deactivate[slug-1,slug-2,...,slug-N]
    task deactivate: :environment do |_t, params|
      slugs = params.to_a
      Team.where(slug: slugs).find_each do |team|
        Team.activate(team.id, false)
      end
    end
    # bundle exec rails check:team:list_teams_with_number_of_members[x]
    desc 'List all teams with members less than or equal X'
    task list_teams_with_number_of_members: :environment do |_t, number|
      number = number.to_a.first.to_i
      puts "number:: #{number}"
      output = []
      TeamUser.select('team_id, count(team_id) as m_count')
      .where(type: nil).group('team_id')
      .having("count(team_id) <= ?", number).each do |tu|
        print '.'
        t = Team.find_by_id(tu.team_id)
        output << { team_id: tu.team_id, slug: t.slug, members: tu.m_count }
      end
      pp output
    end
    # bundle exec rails check:team:list_inactive_teams[x]
    desc 'List all teams with no activities since X months ago'
    task list_inactive_teams: :environment do |_t, number|
      number = number.to_a.first.to_i
      date = Time.now - number.months
      puts "number:: #{number}"
      output = []
      Team.find_each do |team|
        print '.'
        logs = Version.from_partition(team.id).where('created_at > ?', date).count
        output << { team_id: team.id, slug: team.slug } if logs == 0
      end
      pp output
    end
  end
end