# When the parsed page returns `@username` as `author_name` Pender ignores it
# If there are more patterns that should be ignored when found on page, they need to be added on the method below:
# https://github.com/meedan/pender/blob/d401df71c075538384450fdb3b8711155b5da757/app/models/concerns/media_twitter_item.rb#L80-L82

# To run this task updating the sources that have a name that should be ignored:
# bundle exec rake check:migrate:fix_sources_names['@username']

def untitled_name
  "Untitled-#{Time.now.strftime('%Y%m%d%H%M%S%L')}"
end

def create_new_source(s, author_name, default_name)
  new_source = Source.new
  new_source.name = (author_name.blank? || author_name.downcase == @name) ? default_name : author_name
  new_source.team = s.team unless s.team.nil?
  new_source.skip_check_ability = true
  new_source.save!
  new_source
end

def update_source_name(source, name)
  source.name = name
  source.updated_at = Time.now
  source.save!
end

namespace :check do
  namespace :migrate do
    task :fix_sources_names, [:name] => :environment do |t, args|
      RequestStore.store[:skip_notifications] = true
      @name = args[:name].downcase
      total = Source.where(name: @name).count

      LIMIT = 1000

      sum = 0
      failed_sources = {}
      failed_account_sources = {}
      n = Source.where(name: @name).order('id ASC').limit(LIMIT).count
      while n > 0
        puts "[#{Time.now}] Starting to replace #{n} Sources with name `#{@name}` and split accounts: #{sum} replaced, #{total - sum} remaining..."
        sum += n
        i = 0

        Source.where(name: @name).order('id ASC').limit(LIMIT).each do |s|
          i += 1

          accounts_size = AccountSource.where(source_id: s.id).includes(:account).count
          if accounts_size.zero?
            update_source_name(s, untitled_name)
            next
          end

          j = 0
          AccountSource.where(source_id: s.id).includes(:account).each do |as|
            j += 1
            print "Source #{i}/#{n} - Account: #{j}/#{accounts_size}  \r"
            $stdout.flush

            account = as.account
            account.refresh_metadata

            default_name = (s.name.downcase != @name) ? s.name : untitled_name
            data = account.data
            begin
              if data.nil?
                update_source_name(s, default_name) if s.name.blank? || s.name.downcase == @name
              elsif s.name.blank? || s.name.start_with?('Untitled') || s.name.downcase == @name || data['author_name'].blank? || data['author_name'].downcase == @name
                new_name = (data['author_name'].blank? || data['author_name'].downcase == @name) ? default_name : data['author_name']
                update_source_name(s, new_name)
              elsif s.name != data['author_name']
                existent = Source.get_duplicate(data['author_name'], s.team) unless s.team.nil?
                begin
                  as.source = existent || create_new_source(s, data['author_name'], default_name)
                  as.save!
                rescue StandardError => e
                  failed_account_sources[as.id] = { error: e.message, as: as.id }
                end
              end
            rescue StandardError => e
             failed_sources[s.id] = e.message
            end
          end
        end

        n = Source.where(name: @name).order('id ASC').limit(LIMIT).count
      end

      puts "[#{Time.now}] Done!"
      puts "Sources with name #{@name}: #{Source.where(name: @name).order('id ASC').limit(LIMIT).count}"
      puts "#{failed_sources.size} sources failed to update. Ids: #{failed_sources.map(&:inspect)}"
      puts "#{failed_account_sources.size} account sources failed to update. Ids: #{failed_account_sources.map(&:inspect)}"
      RequestStore.store[:skip_notifications] = false
    end
  end
end
