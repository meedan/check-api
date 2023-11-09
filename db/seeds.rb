include SampleData
require "faker"

Rails.env.development? || raise('To run the seeds file you should be in the development environment')

Rails.cache.clear

data = {
  team_name: Faker::Company.name,
  user_name: Faker::Name.first_name.downcase,
  user_password: Faker::Internet.password(min_length: 8),
  link_media_links: [
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

  ],
  audios: ['e-item.mp3', 'rails.mp3', 'with_cover.mp3', 'with_cover.ogg', 'with_cover.wav', 'e-item.mp3', 'rails.mp3', 'with_cover.mp3', 'with_cover.ogg'],
  images: ['large-image.jpg', 'maçã.png', 'rails-photo.jpg', 'rails.png', 'rails2.png', 'ruby-big.png', 'ruby-small.png', 'ruby-big.png', 'ruby-small.png'],
  videos: ['d-item.mp4', 'rails.mp4', 'd-item.mp4', 'rails.mp4', 'd-item.mp4', 'rails.mp4', 'd-item.mp4', 'rails.mp4', 'd-item.mp4'],
  fact_check_links: [
    'https://meedan.com/post/welcome-haramoun-hamieh-our-program-manager-for-nawa',
    'https://meedan.com/post/strengthening-fact-checking-with-media-literacy-technology-and-collaboration',
    'https://meedan.com/post/highlights-from-the-work-of-meedans-partners-on-international-fact-checking',
    'https://meedan.com/post/what-is-gendered-health-misinformation-and-why-is-it-an-equity-problem-worth',
    'https://meedan.com/post/the-case-for-a-public-health-approach-to-moderate-health-misinformation',
  ],
  claims: Array.new(9) { Faker::Lorem.paragraph(sentence_count: 10) },
}

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

def add_claim_descriptions_and_fact_checks(user, project_medias)
  claim_descriptions = project_medias.map { |project_media| ClaimDescription.create!(description: create_description(project_media), context: Faker::Lorem.sentence, user: user, project_media: project_media) }
  claim_descriptions.values_at(0,3,8).each { |claim_description| FactCheck.create!(summary: Faker::Company.catch_phrase, title: Faker::Company.name, user: user, claim_description: claim_description, language: 'en') }
end

def fact_check_attributes(fact_check_link, user, project, team)
  {
    summary: Faker::Company.catch_phrase,
    url: fact_check_link,
    title: Faker::Company.name,
    user: user,
    claim_description: create_claim_description(user, project, team)
  }
end

def create_blank(project, team)
  ProjectMedia.create!(project: project, team: team, media: Blank.create!, channel:  { main: CheckChannels::ChannelCodes::FETCH })
end

def create_claim_description(user, project, team)
  ClaimDescription.create!(description: Faker::Company.catch_phrase, context: Faker::Lorem.sentence, user: user, project_media: create_blank(project, team))
end

def create_relationship(project_medias)
  Relationship.create!(source_id: project_medias[0].id, target_id: project_medias[1].id, relationship_type: Relationship.confirmed_type)
  Relationship.create!(source_id: project_medias[2].id, target_id: project_medias[3].id, relationship_type: Relationship.confirmed_type)
  
  project_medias[4..9].each { |pm| Relationship.create!(source_id: project_medias[2].id, target_id: pm.id, relationship_type: Relationship.suggested_type)}    
end

def create_tipline_project_media(user, project, team, media)
  ProjectMedia.create!(user_id: user.id, project: project, team: team, media: media, channel: { main: CheckChannels::ChannelCodes::WHATSAPP })
end

def create_tipline_user_and_data(project_media, team)
  tipline_user_name = Faker::Name.first_name.downcase
  tipline_user_surname = Faker::Name.last_name
  tipline_text = Faker::Lorem.paragraph(sentence_count: 10)
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
      'type': 'whatsapp',
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
    'text': tipline_text,
    'language': 'en',
    'mediaUrl': nil,
    'mediaSize': 0,
    'archived': 3,
    'app_id': random_string
  }

  fields = {
    smooch_request_type: 'default_requests',
    smooch_data: smooch_data.to_json
  }

  Dynamic.create!(annotation_type: 'smooch', annotated: project_media, annotator: BotUser.smooch_user, set_fields: fields.to_json)
end

def create_tipline_requests(team, project, user, data_instances, model_string)
  tipline_pm_arr = []
  
  data_instances.each do |data_instance|
    media = create_media(user, data_instance, model_string)
    project_media = create_tipline_project_media(user, project, team, media)
    tipline_pm_arr.push(project_media)
  end
  add_claim_descriptions_and_fact_checks(user, tipline_pm_arr)
  create_relationship(tipline_pm_arr)

  tipline_pm_arr.values_at(0,3,6).each {|pm| create_tipline_user_and_data(pm, team)}
  tipline_pm_arr.values_at(1,4,7).each {|pm| 15.times {create_tipline_user_and_data(pm, team)}}
  tipline_pm_arr.values_at(2,5,8).each {|pm| 20.times {create_tipline_user_and_data(pm, team)}}
end

puts "If you want to create a new user: press 1 then enter"
puts "If you want to add more data to an existing user: press 2 then enter"
print ">> "
answer = STDIN.gets.chomp

ActiveRecord::Base.transaction do
  if answer == "1"
    puts 'Making Team / Workspace...'
    team = create_team(name: "#{data[:team_name]} / Feed Creator")
    team.set_language('en')

    puts 'Making User...'
    user = create_user(name: data[:user_name], login: data[:user_name], password: data[:user_password], password_confirmation: data[:user_password], email: Faker::Internet.safe_email(name: data[:user_name]), is_admin: true)

    puts 'Making Project...'
    project = create_project(title: team.name, team_id: team.id, user: user, description: '')

    puts 'Making Team User...'
    create_team_user(team: team, user: user, role: 'admin')
  elsif answer == "2"
    puts "Type user email then press enter"
    print ">> "
    email = STDIN.gets.chomp

    puts "Fetching User, Project, Team User and Team..."
    user = User.find_by(email: email)

    if user.team_users.first.nil?
      team = create_team(name: data[:team_name])
      project = create_project(title: team.name, team_id: team.id, user: user, description: '')
      create_team_user(team: team, user: user, role: 'admin')
    else 
      team_user = user.team_users.first
      team = team_user.team
      project = user.projects.first
    end
  end

  puts 'Making Medias...'
  puts 'Making Medias and Project Medias: Claims...'
  claims = data[:claims].map { |data| create_media(user, data, 'Claim')}
  claim_project_medias = create_project_medias(user, project, team, claims)
  add_claim_descriptions_and_fact_checks(user, claim_project_medias)

  puts 'Making Medias and Project Medias: Links...'
  begin
    links = data[:link_media_links].map { |data| create_media(user, data, 'Link')}
    link_project_medias = create_project_medias(user, project, team, links)
    add_claim_descriptions_and_fact_checks(user, link_project_medias)
  rescue
    puts "Couldn't create Links. Other medias will still be created. \nIn order to create Links make sure Pender is running."
  end

  puts 'Making Medias and Project Medias: Audios...'
  audios = data[:audios].map { |data| create_media(user, data, 'UploadedAudio')}
  audio_project_medias = create_project_medias(user, project, team, audios)
  add_claim_descriptions_and_fact_checks(user, audio_project_medias)

  puts 'Making Medias and Project Medias: Images...'
  images = data[:images].map { |data| create_media(user, data, 'UploadedImage')}
  image_project_medias = create_project_medias(user, project, team, images)
  add_claim_descriptions_and_fact_checks(user, image_project_medias)

  puts 'Making Medias and Project Medias: Videos...'
  videos = data[:videos].map { |data| create_media(user, data, 'UploadedVideo')}
  video_project_medias = create_project_medias(user, project, team, videos)
  add_claim_descriptions_and_fact_checks(user, video_project_medias)

  puts 'Making Claim Descriptions and Fact Checks: Imported Fact Checks...'
  data[:fact_check_links].map { |fact_check_link| create_fact_check(fact_check_attributes(fact_check_link, user, project, team)) }

  puts 'Making Relationship...'
  puts 'Making Relationship: Claims / Confirmed Type and Suggested Type...'
  create_relationship(claim_project_medias)

  puts 'Making Relationship: Links / Suggested Type...'
  begin
    create_relationship(link_project_medias)
  rescue
    puts "Couldn't create Links. Other medias will still be created. \nIn order to create Links make sure Pender is running."
  end

  puts 'Making Relationship: Audios / Confirmed Type and Suggested Type...'
  create_relationship(audio_project_medias)

  puts 'Making Relationship: Images / Confirmed Type and Suggested Type...'
  create_relationship(image_project_medias)

  puts 'Making Relationship: Videos / Confirmed Type and Suggested Type...'
  create_relationship(video_project_medias)

  puts 'Making Tipline requests...'
  puts 'Making Tipline requests: Claims...'
  create_tipline_requests(team, project, user, data[:claims], 'Claim')

  puts 'Making Tipline requests: Links...'
  begin
    create_tipline_requests(team, project, user, data[:link_media_links], 'Link')
  rescue
    puts "Couldn't create Links. Other medias will still be created. \nIn order to create Links make sure Pender is running."
  end

  puts 'Making Tipline requests: Audios...'
  create_tipline_requests(team, project, user, data[:audios], 'UploadedAudio')

  puts 'Making Tipline requests: Images...'
  create_tipline_requests(team, project, user, data[:images], 'UploadedImage')

  puts 'Making Tipline requests: Videos...'
  create_tipline_requests(team, project, user, data[:videos], 'UploadedVideo')

  puts 'Making Shared Feed'
  saved_search = SavedSearch.create!(title: "#{data[:user_name]}'s list", team: team, filters: {created_by: data[:user_name]})
  Feed.create!(name: "Feed Test #{Faker::Alphanumeric.alpha(number: 10)}", user: user, team: team, published: true, saved_search: saved_search)

  if answer == "1"
    puts "Created user: name: #{data[:user_name]} — email: #{user.email} — password : #{data[:user_password]}"
  elsif answer == "2"
    puts "Data added to user: #{user.email}"
  end
end
