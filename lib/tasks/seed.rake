namespace :db do
  namespace :seed do
    # Create random data (actually this is an alias for `rake db:seed`
    task :random do
      Rake::Task['db:seed'].invoke
    end

    # Create data from CSV files under db/data
    task sample: :environment do
      require 'csv'
      require 'yaml'
      require 'open-uri'

      ignore = ENV['ignore'].blank? ? [] : ENV['ignore'].split(',')

      Dir.glob(File.join(Rails.root, 'db', 'data', '*/')).each do |dir|
        puts "Start migration for #{dir} ...."
        mapping_ids = Hash.new()
        mapping_file = File.join(dir, 'mapping_ids.yml')
        if File.exist?mapping_file
          mapping_ids = YAML::load_file mapping_file
        else
          File.new(mapping_file, "w")
        end
        # Iterate through CSV files for a given team
        Dir.glob(File.join(dir, '*.csv')).sort.each do |file|

          if ignore.include?(file.gsub(/^.*\//, ''))
            puts "Ignoring #{file}..."
          else
            puts "Parsing #{file}..."
            name = file.gsub(/.*[0-9]_([^\.]+)\.csv/, '\1')
            if mapping_ids.include?(name)
              puts "#{name} were migrated ....."
              next
            end
            model = name.singularize.camelize.constantize

            # model.delete_all
            #ActiveRecord::Base.connection.execute("ALTER TABLE #{name} AUTO_INCREMENT = 1")
            CSV.foreach(file, quote_char: '`', :headers => true) do |row|
              # TODO: add a check for model exists
              data = model.new
              if data.class.name == 'Status'
                # Load existing one
                pm_id = mapping_ids[row["annotated_id"]]
                pm = ProjectMedia.where(id: pm_id).last
                status = pm.get_annotations('status').last unless pm.nil?
                next if status.nil?
                data = status.load unless status.nil?
              end
              old_id = 0
              row.each do |method, value|
                if data.respond_to?(method + '_callback')
                  value = data.send(method + '_callback', value, mapping_ids)
                end

                if method == 'id'
                  old_id = value
                elsif data.respond_to?(method + '=')
                  data.send(method + '=', value)
                elsif data.respond_to?(method)
                  data.send(method, value)
                else
                  puts "#{data} does not respond to #{method}!"
                end
              end

              if data.valid?
                # Set Current user to log versions
                User.current = data.user if data.respond_to?(:user)
                User.current = data.annotator if data.is_annotation?
                data.skip_check_ability = true
                data.save!
                data.confirm if data.class.name == 'User'
                unless old_id.nil? || old_id == 0
                  mapping_ids[old_id] = data.id
                  # Write mapping to yml file
                  File.open(mapping_file, "w") do |yml|
                    yml.write mapping_ids.to_yaml
                  end
                end
              else
                puts "Failed to save #{model} [#{data.errors.messages}]"
              end
            end
            # Mark migrated files on mapping ids
            mapping_ids[name] = true
            File.open(mapping_file, "w") do |yml|
              yml.write mapping_ids.to_yaml
            end
          end
        end
      end
    end

  end
end
