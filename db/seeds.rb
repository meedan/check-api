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
  quotes: ['Garlic can help you fight covid', 'Tea with garlic is a covid treatment', 'If you have covid you should eat garlic', 'Are you allergic to garlic?', 'Vampires can\'t eat garlic']
}

def open_file(file)
  File.open(File.join(Rails.root, 'test', 'data', file))
end

def create_project_medias(user, project, team, n_medias = 9)
  Media.last(n_medias).each { |media| ProjectMedia.create!(user_id: user.id, project: project, team: team, media: media) }
end

def humanize_link(link)
  path = URI.parse(link).path
    path.remove('/post/').underscore.humanize
end

def create_description(project_media)
  Media.last.type == "Link" ? humanize_link(Media.find(project_media.media_id).url) : Faker::Company.catch_phrase
end

def add_claim_descriptions_and_fact_checks(user,n_project_medias = 6, n_claim_descriptions = 3)
  ProjectMedia.last(n_project_medias).each { |project_media| ClaimDescription.create!(description: create_description(project_media), context: Faker::Lorem.sentence, user: user, project_media: project_media) }
  ClaimDescription.last(n_claim_descriptions).each { |claim_description| FactCheck.create!(summary: Faker::Company.catch_phrase, title: Faker::Company.name, user: user, claim_description: claim_description) }
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
  ProjectMedia.create!(project: project, team: team, media: Blank.create!)
end

def create_claim_description(user, project, team)
  ClaimDescription.create!(description: Faker::Company.catch_phrase, context: Faker::Lorem.sentence, user: user, project_media: create_blank(project, team))
end

ActiveRecord::Base.transaction do
  p '...Seeding...'
  p 'Making Team / Workspace...'
  team = create_team(name: Faker::Company.name)

  p 'Making User...'
  user = create_user(name: data[:user_name], login: data[:user_name], password: data[:user_password], password_confirmation: data[:user_password], email: Faker::Internet.safe_email(name: data[:user_name]), is_admin: true)

  p 'Making Project...'
  project = create_project(title: team.name, team_id: team.id, user: user, description: '')

  p 'Making Team User...'
  create_team_user(team: team, user: user, role: 'admin')

  p 'Making Medias...'
  p 'Making Medias and Project Medias: Claims...'
  9.times { Claim.create!(user_id: user.id, quote: Faker::Quotes::Shakespeare.hamlet_quote) }
  create_project_medias(user, project, team)
  add_claim_descriptions_and_fact_checks(user)

  p 'Making Medias and Project Medias: Links...'
  begin
    data[:link_media_links].each { |link_media_link| Link.create!(user_id: user.id, url: link_media_link+"?timestamp=#{Time.now.to_f}") }
    create_project_medias(user, project, team)
    add_claim_descriptions_and_fact_checks(user)
  rescue
    puts "Couldn't create Links. Other medias will still be created. \nIn order to create Links, Please make sure Pender is working properly and running."
  end

  p 'Making Medias and Project Medias: Audios...'
  data[:audios].each { |audio| UploadedAudio.create!(user_id: user.id, file: open_file(audio)) }
  create_project_medias(user, project, team)
  add_claim_descriptions_and_fact_checks(user)

  p 'Making Medias and Project Medias: Images...'
  data[:images].each { |image| UploadedImage.create!(user_id: user.id, file: open_file(image))}
  create_project_medias(user, project, team)
  add_claim_descriptions_and_fact_checks(user)

  p 'Making Medias and Project Medias: Videos...'
  data[:videos].each { |video| UploadedVideo.create!(user_id: user.id, file: open_file(video)) }
  create_project_medias(user, project, team)
  add_claim_descriptions_and_fact_checks(user)

  p 'Making Claim Descriptions and Fact Checks: Imported Fact Checks...'
  begin
    data[:fact_check_links].each { |fact_check_link| create_fact_check(fact_check_attributes(fact_check_link+"?timestamp=#{Time.now.to_f}", user, project, team)) }
  rescue
    puts "Couldn't create Imported Fact Checks. Other medias will still be created. \nIn order to create Imported Fact Checks, Please make sure Pender is working properly and running."
  end

  p 'Making Relationship between Claims...'
  relationship_claims = []
  project_medias_for_relationship_claims = []
  data[:quotes].each { |quote| relationship_claims.push(Claim.create!(user_id: user.id, quote: quote)) }
  relationship_claims.each { |claim| project_medias_for_relationship_claims.push(ProjectMedia.create!(user_id: user.id, project: project, team: team, media: claim))}

  Relationship.create!(source_id: project_medias_for_relationship_claims[0].id, target_id: project_medias_for_relationship_claims[1].id, relationship_type: Relationship.confirmed_type)
  Relationship.create!(source_id: project_medias_for_relationship_claims[0].id, target_id: project_medias_for_relationship_claims[2].id, relationship_type: Relationship.confirmed_type)
  Relationship.create!(source_id: project_medias_for_relationship_claims[3].id, target_id: project_medias_for_relationship_claims[4].id, relationship_type: Relationship.suggested_type)

  p 'Making Relationship between Images...'
  project_medias_for_images = []
  2.times { project_medias_for_images.push(ProjectMedia.create!(user_id: user.id, project: project, team: team, media: UploadedImage.create!(user_id: user.id, file: File.open(File.join(Rails.root, 'test', 'data', 'rails.png'))))) }
  Relationship.create!(source_id: project_medias_for_images[0].id, target_id: project_medias_for_images[1].id, relationship_type: Relationship.confirmed_type)

  p 'Making Relationship between Audios...'
  project_medias_for_audio = []
  2.times { project_medias_for_audio.push(ProjectMedia.create!(user_id: user.id, project: project, team: team, media: UploadedAudio.create!(user_id: user.id, file: File.open(File.join(Rails.root, 'test', 'data', 'rails.mp3'))))) }
  Relationship.create!(source_id: project_medias_for_audio[0].id, target_id: project_medias_for_audio[1].id, relationship_type: Relationship.confirmed_type)

  p 'Making Tipline requests...'
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

      a = Dynamic.new(annotation_type: 'smooch', annotated: project_media, annotator: BotUser.smooch_user)
      a.set_fields = fields.to_json
      a.save!
  end

  add_claim_descriptions_and_fact_checks(user)

  p "Created — user: #{data[:user_name]} — email: #{user.email} — password : #{data[:user_password]}"
end