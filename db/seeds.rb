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
  related_claims:  Array.new(12) { Faker::Lorem.paragraph(sentence_count: 2) }
}

def open_file(file)
  File.open(File.join(Rails.root, 'test', 'data', file))
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
  project_medias.each { |project_media| ClaimDescription.create!(description: create_description(project_media), context: Faker::Lorem.sentence, user: user, project_media: project_media) }
  ClaimDescription.last(3).each { |claim_description| FactCheck.create!(summary: Faker::Company.catch_phrase, title: Faker::Company.name, user: user, claim_description: claim_description) }
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

puts "If you want to create a new user: press 1 then enter"
puts "If you want to add more data to an existing user: press 2 then enter"
print ">> "
answer = STDIN.gets.chomp

ActiveRecord::Base.transaction do
  if answer == "1"
    puts 'Making Team / Workspace...'
    team = create_team(name: Faker::Company.name)

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
      team = create_team(name: Faker::Company.name)
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
  claims = Array.new(9) { Claim.create!(user_id: user.id, quote: Faker::Quotes::Shakespeare.hamlet_quote) }
  claims_project_medias = create_project_medias(user, project, team, claims)
  add_claim_descriptions_and_fact_checks(user, claims_project_medias)

  puts 'Making Medias and Project Medias: Links...'
  begin
    links = data[:link_media_links].map { |link_media_link| Link.create!(user_id: user.id, url: link_media_link+"?timestamp=#{Time.now.to_f}") }
    links_project_medias = create_project_medias(user, project, team, links)
    add_claim_descriptions_and_fact_checks(user, links_project_medias)
  rescue
    puts "Couldn't create Links. Other medias will still be created. \nIn order to create Links make sure Pender is running."
  end

  puts 'Making Medias and Project Medias: Audios...'
  audios = data[:audios].map { |audio| UploadedAudio.create!(user_id: user.id, file: open_file(audio)) }
  audio_project_medias = create_project_medias(user, project, team, audios)
  add_claim_descriptions_and_fact_checks(user, audio_project_medias)

  puts 'Making Medias and Project Medias: Images...'
  images = data[:images].map { |image| UploadedImage.create!(user_id: user.id, file: open_file(image))}
  image_project_medias = create_project_medias(user, project, team, images)
  add_claim_descriptions_and_fact_checks(user, image_project_medias)

  puts 'Making Medias and Project Medias: Videos...'
  videos = data[:videos].map { |video| UploadedVideo.create!(user_id: user.id, file: open_file(video)) }
  video_project_medias = create_project_medias(user, project, team, videos)
  add_claim_descriptions_and_fact_checks(user, video_project_medias)

  puts 'Making Claim Descriptions and Fact Checks: Imported Fact Checks...'
  data[:fact_check_links].each { |fact_check_link| create_fact_check(fact_check_attributes(fact_check_link, user, project, team)) }

  puts 'Making Relationship...'
  puts 'Making Relationship: Claims...'
  project_medias_for_related_claims = []
  related_claims = data[:related_claims].map { |quote| Claim.create!(user_id: user.id, quote: quote) }
  related_claims.each { |claim| project_medias_for_related_claims.push(ProjectMedia.create!(user_id: user.id, project: project, team: team, media: claim))}

  puts 'Making Relationship: Claims / Confirmed Type...'
  Relationship.create!(source_id: project_medias_for_related_claims[0].id, target_id: project_medias_for_related_claims[1].id, relationship_type: Relationship.confirmed_type)
  Relationship.create!(source_id: project_medias_for_related_claims[0].id, target_id: project_medias_for_related_claims[2].id, relationship_type: Relationship.confirmed_type)

  puts 'Making Relationship: Claims / Suggested Type...'
  project_medias_for_related_claims[4..12].each do |pm_claim|
    Relationship.create!(source_id: project_medias_for_related_claims[3].id, target_id: pm_claim.id, relationship_type: Relationship.suggested_type)
  end

  puts 'Making Relationship: Links / Suggested Type...'
  begin
    links_project_medias[1..9].each do |pm_link|
      Relationship.create!(source_id: links_project_medias[0].id, target_id: pm_link.id, relationship_type: Relationship.suggested_type)
    end
  rescue
    puts "Couldn't create Links. Other medias will still be created. \nIn order to create Links make sure Pender is running."    
  end

  puts 'Making Relationship: Audios / Confirmed Type...'
  project_medias_for_audio = []
  2.times { project_medias_for_audio.push(ProjectMedia.create!(user_id: user.id, project: project, team: team, media: UploadedAudio.create!(user_id: user.id, file: File.open(File.join(Rails.root, 'test', 'data', 'rails.mp3'))))) }
  Relationship.create!(source_id: project_medias_for_audio[0].id, target_id: project_medias_for_audio[1].id, relationship_type: Relationship.confirmed_type)

  puts 'Making Relationship: Images / Confirmed Type...'
  project_medias_for_images = []
  2.times { project_medias_for_images.push(ProjectMedia.create!(user_id: user.id, project: project, team: team, media: UploadedImage.create!(user_id: user.id, file: File.open(File.join(Rails.root, 'test', 'data', 'rails.png'))))) }
  Relationship.create!(source_id: project_medias_for_images[0].id, target_id: project_medias_for_images[1].id, relationship_type: Relationship.confirmed_type)

  puts 'Making Tipline requests...'
  9.times do
    claim_media = Claim.create!(user_id: user.id, quote: Faker::Lorem.paragraph(sentence_count: 10))
    project_media = ProjectMedia.create!(project: project, team: team, media: claim_media, channel: { main: CheckChannels::ChannelCodes::WHATSAPP })

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

  tipline_claims_project_medias = ProjectMedia.last(9)
  add_claim_descriptions_and_fact_checks(user, tipline_claims_project_medias)

  if answer == "1"
    puts "Created — user: #{data[:user_name]} — email: #{user.email} — password : #{data[:user_password]}"
  elsif answer == "2"
    puts "Data added to user: #{user.email}"
  end
end
