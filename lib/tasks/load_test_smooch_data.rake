namespace :test do
  namespace :data do
    task smooch: :environment do |_task|
      require 'sample_data'
      include SampleData

      # Customize input data here
      check_base_url = 'http://localhost:3000' # 'https://check-api.checkmedia.org'
      concurrency = 40
      repeats = 250

      secret = 'test'
      app_id = 'get one on Smooch page'
      puts "[#{Time.now}] Please use smooch_webhook_secret '#{secret}' and smooch_app_id '#{app_id}' on your Smooch Bot settings"

      # Prepare the numbers
      times = concurrency * repeats
      puts "[#{Time.now}] Running for #{concurrency} concurrent users, #{repeats} times (total: #{times} requests)"

      # Generate a file with random requests

      filename = "urls-#{random_string}.txt"
      puts "[#{Time.now}] Generating file with random requests at tmp/#{filename}"
      filepath = File.join(Rails.root, 'tmp', filename)
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
                    { type: 'text', text: random_string(100) }
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
        file.puts "#{check_base_url}/api/webhooks/smooch POST #{params}"
      end
      puts "[#{Time.now}] Generated file with random requests"
      file.close

      # Run Siege

      puts "[#{Time.now}] Running Siege"
      sh "siege --concurrent=#{concurrency} --reps=#{repeats} --content-type='application/json' --header='X-Check-Smooch-Queue: siege' --header='X-API-Key: #{secret}' --file=#{filepath} 2>&1"
      puts "[#{Time.now}] Siege ran"


      # Confirm the requests
      puts "[#{Time.now}] Confirming requests"
      sleep 10
      pool = []
      user_ids.each_slice(repeats).to_a.each do |uids|
        puts "[#{Time.now}] Starting thread to confirm requests..."
        pool << Thread.new do
          uids.each do |uid|
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
            confirm = %x(curl -XPOST -H 'X-API-Key: #{secret}' -H 'X-Check-Smooch-Queue: siege' -H 'Content-Type: application/json' -d '#{payload}' #{check_base_url}/api/webhooks/smooch 2>/dev/null ; echo)
          end # uids.each
        end # Thread.new
      end # each_slice
      pool.each(&:join)

      puts "[#{Time.now}] Done!"
    end
  end
end
