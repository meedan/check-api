# Move all items that are:
# [in the list connected to Check Message OR All Items] AND [not in any other lists] AND [status: team_initial_status]


def check_message_list(t)
  bot_user = BotUser.where(name: 'Smooch').last
  bot = t.team_bot_installations.find_by_user_id bot_user.id
  bot ? bot.settings['smooch_project_id'] : nil
end

def team_initial_status(t)
  t.media_verification_statuses['default']
end

def is_orphan_or_only_smooch_list?(pm, list)
  pm.project_id.nil? || (pm.project_ids == [list])
end

def should_archive?(pm, list, initial_status)
  is_orphan_or_only_smooch_list?(pm, list) && (pm.status == initial_status)
end

namespace :check do
  # bundle exec rake check:move_smooch_messages_to_trash[slug1,slug2,slug3]
  desc "Move smooch messages to trash"
  task move_smooch_messages_to_trash: :environment do |_t, args|
    puts "Please send the slugs of the teams. Example:\n`bundle exec rake check:move_smooch_messages_to_trash[slug1,slug2,slug3]`" if args.extras.empty?
    args.extras.each do |slug|
      puts "[#{Time.now}] Team '#{slug}..."
      pms_ids = []
      team = Team.find_by_slug slug
      if team.nil?
        puts "  Could not find team with slug '#{slug}'"
        next
      end
      if list = check_message_list(team)
        initial_status = team_initial_status(team)
        puts "  Checking messages from '#{slug}' to move to trash"
        n = team.project_medias.where(archived: false).count
        i = 0
        team.project_medias.where(archived: false).find_each do |pm|
          i += 1
          if should_archive?(pm, list, initial_status)
            pms_ids << pm.id
          end
          print "#{i}/#{n} items checked...\r"
          $stdout.flush
        end
        ProjectMedia.where(id: pms_ids).update_all(archived: true)
        puts "  #{pms_ids.size} items from team `#{slug}` were moved to trash"
      else
        puts "  Skipping team `#{team.slug}`: no Smooch bot related to it"
      end
    end
    puts "[#{Time.now}] Done!"
  end
end
