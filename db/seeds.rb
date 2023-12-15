include SampleData
require "faker"

Rails.env.development? || raise('To run the seeds file you should be in the development environment')

data_users = {
  main_user: {
    team:
      {
        name: "#{Faker::Company.name} / Main User: Main Team",
        logo: 'rails.png'
      },
    name: Faker::Name.first_name.downcase,
    password: Faker::Internet.password(min_length: 8),
  },
  invited_empty_user: {
    team:
    [
      {
      name: "#{Faker::Company.name} / Invited User: Team #1",
      logo: 'maçã.png'
    },
    {
      name: "#{Faker::Company.name} / Invited User: Team #2",
      logo: 'ruby-small.png'
    }
  ],
    name: Faker::Name.first_name.downcase,
    password: Faker::Internet.password(min_length: 8),
  }
}

data_items = {
  'Link' => [
    'https://meedan.com/post/addressing-misinformation-across-countries-a-pioneering-collaboration-between-taiwan-factcheck-center-vera-files',
    'https://meedan.com/post/entre-becos-a-women-led-hyperlocal-newsletter-from-the-peripheries-of-brazil',
    'https://meedan.com/post/check-global-launches-independent-media-response-fund-tackles-on-climate-misinformation',
    'https://meedan.com/post/chambal-media',
    'https://meedan.com/post/application-process-for-the-check-global-independent-media-response-fund',
    'https://meedan.com/post/fact-checkers-and-their-mental-health-research-work-in-progress',
    'https://meedan.com/post/meedan-stands-with-rappler-in-the-fight-against-disinformation',
    'https://meedan.com/post/2022-french-elections-meedan-software-supported-agence-france-presse',
    'https://meedan.com/post/how-to-write-longform-git-commits-for-better-software-development',
    'https://meedan.com/post/welcome-smriti-singh-our-research-intern',
    'https://meedan.com/post/countdown-to-u-s-2024-meedan-coalition-to-exchange-critical-election-information-with-overlooked-voters',
    'https://meedan.com/post/a-statement-on-the-israel-gaza-war-by-meedans-ceo',
    'https://meedan.com/post/resources-to-capture-critical-evidence-from-the-israel-gaza-war',
    'https://meedan.com/post/turkeys-largest-fact-checking-group-debunks-election-related-disinformation',
    'https://meedan.com/post/meedan-joins-diverse-cohort-of-partners-committed-to-partnership-on-ais-responsible-practices-for-synthetic-media',
    'https://meedan.com/post/nurturing-equity-diversity-and-inclusion-meedans-people-first-approach',
    'https://meedan.com/post/students-find-top-spreader-of-climate-misinformation-is-most-read-online-news-publisher-in-egypt',
    'https://meedan.com/post/new-e-course-on-the-fundamentals-of-climate-and-environmental-reporting-in-africa',
    'https://meedan.com/post/annual-report-2022',
    'https://meedan.com/post/meedan-joins-partnership-on-ais-ai-and-media-integrity-steering-committee'
  ],
  'UploadedAudio' => ['e-item.mp3', 'rails.mp3', 'with_cover.mp3', 'with_cover.ogg', 'with_cover.wav']*4,
  'UploadedImage' =>  ['large-image.jpg', 'maçã.png', 'rails-photo.jpg', 'rails.png', 'ruby-small.png']*4,
  'UploadedVideo' =>  ['d-item.mp4', 'rails.mp4', 'd-item.mp4', 'rails.mp4', 'd-item.mp4']*4,
  'Claim' => Array.new(20) { Faker::Lorem.paragraph(sentence_count: 10) },
}

data_imported_fact_checks =  [
  'https://meedan.com/post/welcome-haramoun-hamieh-our-program-manager-for-nawa',
  'https://meedan.com/post/strengthening-fact-checking-with-media-literacy-technology-and-collaboration',
  'https://meedan.com/post/highlights-from-the-work-of-meedans-partners-on-international-fact-checking',
  'https://meedan.com/post/what-is-gendered-health-misinformation-and-why-is-it-an-equity-problem-worth',
  'https://meedan.com/post/the-case-for-a-public-health-approach-to-moderate-health-misinformation',
]

def open_file(file)
  File.open(File.join(Rails.root, 'test', 'data', file))
end

def create_media(user, data, model_string)
  model = Object.const_get(model_string)
  case model_string
  when 'Claim'
    media = model.create!(user_id: user.id, quote: data)
  when 'Link'
    media = model.create!(user_id: user.id, url: data+"?timestamp=#{Time.now.to_f}")
  else
    media = model.create!(user_id: user.id, file: open_file(data)) 
  end
  media
end

def create_project_medias(user, project, team, data)
  data.map { |media| ProjectMedia.create!(user_id: user.id, project: project, team: team, media: media) }
end

def humanize_link(link)
  path = URI.parse(link).path
  path.remove('/post/').underscore.humanize
end

def create_description(project_media)
  Media.last.type == "Link" ? humanize_link(Media.find(project_media.media_id).url) : Faker::Company.catch_phrase
end

def create_claim_descriptions(user, project_medias)
  project_medias.map { |project_media| ClaimDescription.create!(description: create_description(project_media), context: Faker::Lorem.sentence, user: user, project_media: project_media) }
end

def create_fact_checks(user, claim_descriptions)
  claim_descriptions.each { |claim_description| FactCheck.create!(summary: Faker::Company.catch_phrase, title: Faker::Company.name, user: user, claim_description: claim_description, language: 'en') }
end

def fact_check_attributes(fact_check_link, user, project, team)
  {
    summary: Faker::Company.catch_phrase,
    url: fact_check_link,
    title: Faker::Company.name,
    user: user,
    claim_description: create_claim_description_for_imported_fact_check(user, project, team)
  }
end

def create_blank(project, team)
  ProjectMedia.create!(project: project, team: team, media: Blank.create!, channel:  { main: CheckChannels::ChannelCodes::FETCH })
end

def create_claim_description_for_imported_fact_check(user, project, team)
  ClaimDescription.create!(description: Faker::Company.catch_phrase, context: Faker::Lorem.sentence, user: user, project_media: create_blank(project, team))
end

def create_confirmed_relationship(parent, children)
  [children].flatten.each { |child| Relationship.create!(source_id: parent.id, target_id: child.id, relationship_type: Relationship.confirmed_type) }
end

def create_suggested_relationship(parent, children)
  children.each { |child| Relationship.create!(source_id: parent.id, target_id: child.id, relationship_type: Relationship.suggested_type)} 
end

def create_project_medias_with_channel(user, project, team, data)
  data.map { |media| ProjectMedia.create!(user_id: user.id, project: project, team: team, media: media, channel: { main: CheckChannels::ChannelCodes::WHATSAPP })}
end

def create_tipline_user_and_data(project_media, team)
  tipline_message_data = {
    link: 'https://www.nytimes.com/interactive/2023/09/28/world/europe/russia-ukraine-war-map-front-line.html',
    audio: "#{random_url}/wnHkwjykxOqU3SMWpEpuVzSa.oga",
    video: "#{random_url}/AOVFpYOfMm_ssRUizUQhJHDD.mp4",
    image: "#{random_url}/bOoeoeV9zNA51ecial0eWDG6.jpeg",
    facebook: 'https://www.facebook.com/boomlive/posts/pfbid0ZoZPYTQAAmrrPR2XmpZ2BCPED1UgozxFGxSQiH68Aa6BF1Cvx2uWHyHrFrAwK7RPl',
    instagram: 'https://www.instagram.com/p/CxsV1Gcskk8/?img_index=1',
    tiktok: 'https://www.tiktok.com/@235flavien/video/7271360629615758597?_r=1&_t=8fFCIWTDWVt',
    twitter: 'https://twitter.com/VietFactCheck/status/1697642909883892175',
    youtube: 'https://www.youtube.com/watch?v=4EIHB-DG_JA',
    text: Faker::Lorem.paragraph(sentence_count: 10)
  }

  tipline_user_name = Faker::Name.first_name.downcase
  tipline_user_surname = Faker::Name.last_name
  tipline_message =  tipline_message_data.values.sample((1..10).to_a.sample).join(' ')
  phone = [ Faker::PhoneNumber.phone_number, Faker::PhoneNumber.cell_phone, Faker::PhoneNumber.cell_phone_in_e164, Faker::PhoneNumber.phone_number_with_country_code, Faker::PhoneNumber.cell_phone_with_country_code].sample
  uid = random_string

  # Tipline user
  smooch_user_data = {
    'id': uid,
    'raw': {
      '_id': uid,
      'givenName': tipline_user_name,
      'surname': tipline_user_surname,
      'signedUpAt': Time.now.to_s,
      'properties': {},
      'conversationStarted': true,
      'clients': [
        {
          'id': random_string,
          'status': 'active',
          'externalId': phone,
          'active': true,
          'lastSeen': Time.now.to_s,
          'platform': 'whatsapp',
          'integrationId': random_string,
          'displayName': phone,
          'raw': {
            'profile': {
              'name': tipline_user_name
            },
            'from': phone
          }
        }
      ],
      'pendingClients': []
    },
    'identifier': random_string,
    'app_name': random_string
  }

  fields = {
    smooch_user_id: uid,
    smooch_user_app_id: random_string,
    smooch_user_data: smooch_user_data.to_json
  }
  
  Dynamic.create!(annotation_type: 'smooch_user', annotated: team, annotator: BotUser.smooch_user, set_fields: fields.to_json)

  # Tipline request
  smooch_data = {
    'role': 'appUser',
    'source': {
      'type': ['whatsapp', 'telegram', 'messenger'].sample,
      'id': random_string,
      'integrationId': random_string,
      'originalMessageId': random_string,
      'originalMessageTimestamp': Time.now.to_i
    },
    'authorId': uid,
    'name': tipline_user_name,
    '_id': random_string,
    'type': 'text',
    'received': Time.now.to_f,
    'text': tipline_message,
    'language': 'en',
    'mediaUrl': nil,
    'mediaSize': 0,
    'archived': 3,
    'app_id': random_string
  }
  
  fields = {
    smooch_request_type: ['default_requests', 'timeout_search_requests', 'relevant_search_result_requests'].sample,
    smooch_data: smooch_data.to_json,
    smooch_report_received: [Time.now.to_i, nil].sample
  }

  Dynamic.create!(annotation_type: 'smooch', annotated: project_media, annotator: BotUser.smooch_user, set_fields: fields.to_json)
end

def create_tipline_requests(team, project_medias, x_times)
  project_medias.each {|pm| x_times.times {create_tipline_user_and_data(pm, team)}}
end

def verify_fact_check_and_publish_report(project_media, url = '')
  status = ['verified', 'false'].sample

  verification_status = project_media.last_status_obj
  verification_status.status = status
  verification_status.save!

  report_design = project_media.get_dynamic_annotation('report_design')
  report_design.set_fields = { status_label: status, state: 'published' }.to_json
  report_design.data[:options][:published_article_url] = url
  report_design.action = 'publish'
  report_design.save!
end

def create_team_and_project_related_to_user(user, team_data)
  puts 'Making Team / Workspace...'
  team = create_team(team_data)
  team.set_language('en')

  puts 'Making Project...'
  project = create_project(title: team.name, team_id: team.id, user: user, description: '')

  puts 'Making Team User...'
  create_team_user(team: team, user: user, role: 'admin')

  return team, project
end

######################
# 0. Start the script
puts "If you want to create a new user: press 1 then enter"
puts "If you want to add more data to an existing user: press 2 then enter"
print ">> "
answer = STDIN.gets.chomp

ActiveRecord::Base.transaction do
  # 1. Creating what we need for the workspace
  # We create a user, team and project OR we fetch one
  if answer == "1"
    user = create_user(name: data_users[:main_user][:name], login: data_users[:main_user][:name], password: data_users[:main_user][:password], password_confirmation: data_users[:main_user][:password], email: Faker::Internet.safe_email(name: data_users[:main_user][:name]), is_admin: true)
    team, project = create_team_and_project_related_to_user(user, data_users[:main_user][:team])
  elsif answer == "2"
    puts "Type user email then press enter"
    print ">> "
    email = STDIN.gets.chomp

    puts "Fetching User, Project, Team User and Team..."
    user = User.find_by(email: email)

    if user.team_users.first.nil?
      team, project = create_team_and_project_related_to_user(user, data_users[:main_user][:team])
    else 
      team_user = user.team_users.first
      team = team_user.team
      project = user.projects.first
    end
  end

  # 2. Creating Items in different states
  # 2.1 Create medias: claims, audios, images, videos and links
  data_items.each do |media_type, medias_data|
    begin
      puts "Making #{media_type}..."
      puts "#{media_type}: Making Medias and Project Medias..."
      medias = medias_data.map { |individual_data| create_media(user, individual_data, media_type)}
      project_medias = create_project_medias_with_channel(user, project, team, medias)
      
      puts "#{media_type}: Making Claim Descriptions and Fact Checks..."
      # add claim description to all items, don't add fact checks to all
      claim_descriptions = create_claim_descriptions(user, project_medias)
      claim_descriptions_for_fact_checks = claim_descriptions[0..10]
      create_fact_checks(user, claim_descriptions_for_fact_checks)

      puts "#{media_type}: Making Relationship: Confirmed Type and Suggested Type..."
      # because we want a lot of state variety between items, we are not creating relationships for 7..13
      # send parent and child index
      create_confirmed_relationship(project_medias[0], project_medias[1])
      create_confirmed_relationship(project_medias[2], project_medias[3])
      create_confirmed_relationship(project_medias[4], project_medias[5])
      create_confirmed_relationship(project_medias[6], project_medias[1])
      # send parent and children
      create_suggested_relationship(project_medias[6], project_medias[14..19])

      puts "#{media_type}: Making Relationship: Create item with many confirmed relationships"
      # so the center column on the item page has a good size list to check functionality against
      # https://github.com/meedan/check-api/pull/1722#issuecomment-1798729043
      # create the children we need for the relationship
      confirmed_children_media = data_items.keys.flat_map do |media_type|
        data_items[media_type][0..1].map { |data| create_media(user, data , media_type)}
      end
      confirmed_children_project_medias = create_project_medias(user, project, team, confirmed_children_media)
      # send parent and children
      create_confirmed_relationship(project_medias[0], confirmed_children_project_medias)

      puts "#{media_type}: Making Tipline requests..."
      # we want different ammounts of requests, so we send the item and the number of requests that should be created
      # we jump between numbers so it looks more real in the UI (instead of all 1 requests, then all 15 etc)
      create_tipline_requests(team, project_medias.values_at(0,3,6,9,12,15,18), 1)
      create_tipline_requests(team, project_medias.values_at(1,4,7,10,13,16,19), 15)
      create_tipline_requests(team, project_medias.values_at(2,5,8,11,14,17), 17)

      puts "#{media_type}: Publishing Reports..."
      # we want some published items to have and some to not have published_article_url, because they behave differently in the feed
      # we send the published_article_url when we want one
      project_medias[7..8].each { |pm| verify_fact_check_and_publish_report(pm, "https://www.thespruceeats.com/step-by-step-basic-cake-recipe-304553?timestamp=#{Time.now.to_f}")}
      project_medias[9..10].each { |pm| verify_fact_check_and_publish_report(pm)}
    rescue StandardError => e
      if media_type != 'Link'
        raise e
      else
        puts "Couldn't create Links. Other medias will still be created. \nIn order to create Links make sure Pender is running."
      end
    end
  end
  
  # 2.2 Create medias: imported Fact Checks
  puts 'Making Imported Fact Checks...'
  data_imported_fact_checks.map { |fact_check_link| create_fact_check(fact_check_attributes(fact_check_link, user, project, team)) }

  # 3. Create Shared feed
  puts 'Making Shared Feed'
  saved_search = SavedSearch.create!(title: "#{user.name}'s list #{random_number}", team: team, filters: {created_by: user})
  feed = Feed.create!(name: "Feed Test ##{user.feeds.count + 1} [User: #{user.name} / Team: #{team.name}]", user: user, team: team, published: true, saved_search: saved_search, licenses: [1])

  # 4.1 Create new user with two empty workspaces
  puts 'Making invited user and their 2 empty workspaces...'
  invited_empty_user = create_user(name: data_users[:invited_empty_user][:name], login: data_users[:invited_empty_user][:name], password: data_users[:invited_empty_user][:password], password_confirmation: data_users[:invited_empty_user][:password], email: Faker::Internet.safe_email(name: data_users[:invited_empty_user][:name]), is_admin: true)
  data_users[:invited_empty_user][:team].each  { |team| create_team_and_project_related_to_user(invited_empty_user, team) }

  # 4.2 Invite new user/empty workspace
  puts 'Inviting user to main user\'s feed...'
  create_feed_invitation(email: invited_empty_user.email, feed: feed, user: user)

  # FINAL. Return user information
  if answer == "1"
    puts "Created user: name: #{data_users[:main_user][:name]} — email: #{user.email} — password : #{data_users[:main_user][:password]}"
  elsif answer == "2"
    puts "Data added to user: #{user.email}"
  end
  puts "Created invited user / empty workspace: name: #{data_users[:invited_empty_user][:name]} — email: #{invited_empty_user.email} — password : #{data_users[:invited_empty_user][:password]}"
end

Rails.cache.clear
