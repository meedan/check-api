namespace :test do
  namespace :load do
    task :smooch, [:concurrency, :repeats] => [:environment] do |task, args|
      require 'sample_data'
      include SampleData
      raise 'Please run in test environment' unless Rails.env.test?

      # Create the bot and install it
      BotUser.delete_all
      settings = [
        { name: 'smooch_app_id', label: 'Smooch App ID', type: 'string', default: '' },
        { name: 'smooch_secret_key_key_id', label: 'Smooch Secret Key: Key ID', type: 'string', default: '' },
        { name: 'smooch_secret_key_secret', label: 'Smooch Secret Key: Secret', type: 'string', default: '' },
        { name: 'smooch_webhook_secret', label: 'Smooch Webhook Secret', type: 'string', default: '' },
        { name: 'smooch_template_namespace', label: 'Smooch Template Namespace', type: 'string', default: '' },
        { name: 'smooch_bot_id', label: 'Smooch Bot ID', type: 'string', default: '' },
        { name: 'smooch_project_id', label: 'Check Project ID', type: 'number', default: '' },
        { name: 'smooch_window_duration', label: 'Window Duration (in hours - after this time since the last message from the user, the user will be notified... enter 0 to disable)', type: 'number', default: 20 }
      ]
      team = create_team
      bot = create_team_bot name: 'Smooch', identifier: 'smooch', approved: true, settings: settings
      project = create_project team_id: team.id
      secret = random_string
      app_id = random_string(24)
      settings = { 'smooch_project_id' => project.id, 'smooch_bot_id' => random_string, 'smooch_webhook_secret' => secret, 'smooch_app_id' => app_id, 'smooch_secret_key_key_id' => random_string, 'smooch_secret_key_secret' => random_string, 'smooch_template_namespace' => random_string, 'smooch_window_duration' => 10 }
      installation = create_team_bot_installation user_id: bot.id, settings: settings, team_id: team.id
      Bot::Smooch.get_installation('smooch_webhook_secret', secret)
      
      # Prepare the numbers

      project_id = project.id
      Sidekiq::Queue.new.clear
      project = Project.find(project_id)
      ProjectMedia.where(project_id: project_id).delete_all
      concurrency = args[:concurrency] || 10
      repeats = args[:repeats] || 50
      times = concurrency * repeats
      puts "[#{Time.now}] Running for #{concurrency} concurrent users, #{repeats} times (total: #{times} requests)"

      # Generate a file with random requests

      puts "[#{Time.now}] Generating file with random requests"
      filepath = File.join(Rails.root, 'tmp', "urls-#{random_string}.txt")
      file = File.open(filepath, 'w+')
      integration_id = random_string(24)
      urls = []
      images = []
      user_ids = []
      times.times do |i|
        user_id = random_string(23) + i.to_s
        user_ids << user_id
        print '.'
        message = case i % 3
                  when 0
                    { type: 'text', text: random_string(rand(500) + 100) }
                  when 1
                    url = ''
                    while url == '' || urls.include?(url)
                      url = begin
                              Net::HTTP.get_response(URI('https://en.wikipedia.org/wiki/Special:Random'))['location'].to_s
                            rescue
                              ''
                            end
                      sleep 1
                    end
                    urls << url
                    text1 = random_string(rand(100) + 100)
                    text2 = random_string(rand(100) + 100)
                    { type: 'text', text: [text1, url, text2].join(' ') }
                  when 2
                    url = ''
                    while url == '' || images.include?(url)
                      url = begin
                              Net::HTTP.get_response(URI('https://picsum.photos/380/380/?random'))['location'].to_s
                            rescue
                              ''
                            end
                      url = 'https://picsum.photos' + url unless url.blank?
                      sleep 1
                    end
                    images << url
                    { type: 'image', mediaUrl: url, text: random_string(rand(200) + 100) }
                  end
        params = {
          trigger: 'message:appUser',
          app: {
            '_id': app_id
          },
          version: 'v1.1',
          messages: [
            {
              role: 'appUser',
              received: Time.now.to_f,
              name: random_string,
              authorId: user_id,
              '_id': app_id,
              source: {
                type: 'whatsapp',
                integrationId: integration_id
              }
            }.merge(message)
          ],
          appUser: {
            '_id': user_id,
            conversationStarted: true
          }
        }.to_json
        file.puts "#{CONFIG['checkdesk_base_url']}/api/webhooks/smooch POST #{params}"
      end
      puts "[#{Time.now}] Generated file with random requests"
      file.close

      # Run Siege and monitor Sidekiq
      
      pool = []
      Sidekiq::Queue.new('smooch').clear
      siege = ''
      duration = 0

      pool << Thread.new do
        finished_at = nil
        started_at = nil
        n = Sidekiq::Queue.new('smooch').size
        m = project.project_medias.count
        while m < times
          if m > 0 and started_at.nil?
            started_at = Time.now.to_i
          end
          puts "[#{Time.now}] Number of jobs in Sidekiq queue: #{n}"
          puts "[#{Time.now}] Number of created items: #{m}"
          sleep 5
          n = Sidekiq::Queue.new('smooch').size
          m = project.project_medias.count
        end
        finished_at = Time.now.to_i
        duration = finished_at - started_at
        puts "[#{Time.now}] Sidekiq processed all jobs in #{duration} seconds"
      end

      diff = 0
      
      pool << Thread.new do
        FileUtils.rm_f '/tmp/siege.txt'
        sh "siege --concurrent=#{concurrency} --reps=#{repeats} --content-type='application/json' --header='X-API-Key: #{secret}' --file=#{filepath} --log=/tmp/siege.log 2>&1 | tee -a /tmp/siege.txt"

        # Confirm the requests
        before = Time.now.to_i
        sleep 30
        user_ids.each do |uid|
          payload = {
            trigger: 'message:appUser',
            app: {
              '_id': app_id
            },
            version: 'v1.1',
            messages: [
              {
                role: 'appUser',
                received: Time.now.to_f,
                name: random_string,
                authorId: uid,
                '_id': app_id,
                type: 'text',
                text: '1',
                source: {
                  type: 'whatsapp',
                  integrationId: integration_id
                }
              }
            ],
            appUser: {
              '_id': uid,
              conversationStarted: true
            }
          }.to_json
          confirm = %x(curl -XPOST -H 'X-API-Key: #{secret}' -H 'Content-Type: application/json' -d '#{payload}' #{CONFIG['checkdesk_base_url']}/api/webhooks/smooch 2>/dev/null ; echo)
          while confirm.chomp != '{"type":"success"}'
            puts "Unexpected confirmation response: #{confirm}"
            confirm = %x(curl -XPOST -H 'X-API-Key: #{secret}' -H 'Content-Type: application/json' -d '#{payload}' #{CONFIG['checkdesk_base_url']}/api/webhooks/smooch 2>/dev/null ; echo)
          end
        end
        after = Time.now.to_i
        diff = after - before + 1
      end
      
      pool.each(&:join)

      FileUtils.rm_f filepath

      # Report results
      
      siege_output = File.read('/tmp/siege.txt')
      successful_transactions = siege_output[/Successful transactions:\s*(.*)/, 1].to_i
      failed_transactions = siege_output[/Failed transactions:\s*(.*)/, 1].to_i
      availability = siege_output[/Availability:\s*(.*)/, 1].to_s
      foreground_duration = siege_output[/Response time:\s*(.*) secs/, 1].to_f
      items_count = project.project_medias.count
      max_background_duration = times * 10
      max_foreground_duration = concurrency
      raise("ERROR: Availability was expected to be 100% but was #{availability}") if availability != '100.00 %'
      raise("ERROR: Expected to create #{times} items, but #{items_count} were created") if items_count != times
      raise("ERROR: Expected to take #{max_background_duration} seconds to process all background requests, but it took #{duration} seconds") if duration > max_background_duration
      raise("ERROR: Expected to take #{max_foreground_duration} seconds to process all foreground requests, but it took #{foreground_duration} seconds") if foreground_duration > (max_foreground_duration + diff)
      raise("ERROR: Expected to have 0 failed requests, but had #{failed_transactions}") if failed_transactions > 0
      raise("ERROR: Expected to have #{times} successful requests, but had #{successful_transactions}") if successful_transactions < times

      puts("SUCCESS! #{successful_transactions} successful requests, #{failed_transactions} failed requests, #{availability} availability, #{foreground_duration} seconds to respond on foreground, #{duration} seconds to create #{items_count} items in background.")
    end
  end
end
