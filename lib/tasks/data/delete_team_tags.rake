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
  end
end