namespace :db do
  namespace :seed do
    # Create random data (actually this is an alias for `rake db:seed`
    task :random do
      Rake::Task['db:seed'].invoke
    end

    # Create data from CSV files under db/data
    task sample: :environment do
      require 'csv'
      require 'open-uri'

      ignore = ENV['ignore'].blank? ? [] : ENV['ignore'].split(',')

      mapping_ids = Hash.new()

      Dir.glob(File.join(Rails.root, 'db', 'data', '**/*.csv')).sort.each do |file|

        if ignore.include?(file.gsub(/^.*\//, ''))
          puts "Ignoring #{file}..."
        else
          puts "Parsing #{file}..."
          name = file.gsub(/.*[0-9]_([^\.]+)\.csv/, '\1')
          model = name.singularize.camelize.constantize
          header = []
          # model.delete_all
          #ActiveRecord::Base.connection.execute("ALTER TABLE #{name} AUTO_INCREMENT = 1")
          CSV.foreach(file, quote_char: '`') do |row|
            if header.blank?
              header = row
            else
              # TODO: add a check for model exists
              data = model.new
              old_id = 0
              target_id = 0
              row.each_with_index do |value, index|
                value = JSON.parse(value) unless (value =~ /^[\[\{]/).nil?
                method = header[index]
                if data.respond_to?(method + '_callback')
                  value = data.send(method + '_callback', value, mapping_ids)
                end

                if method == 'id'
                  old_id = value
                elsif method == 'target_id'
                  target_id = value
                elsif data.respond_to?(method + '=')
                  data.send(method + '=', value)
                elsif data.respond_to?(method)
                  data.send(method, value)
                else
                  raise "#{data} does not respond to #{method}!"
                end
              end

              if data.valid?
                User.current = data.user if data.respond_to?(:user)
                User.current = data.annotator if data.is_annotation?
                data.skip_check_ability = true
                data.save!
                data.confirm if data.class.name == 'User'
                unless old_id.nil? || old_id == 0
                  mapping_ids[old_id] = data.id
                end
              else
                puts "Failed to save #{model} [#{data.errors.messages}]"
              end

            end
          end

        end
      end
    end

  end
end
