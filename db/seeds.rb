include SampleData
require "faker"


p '...Seeding...'
p 'Making Team...'
team = create_team(name: Faker::Company.name)

p 'Making User...'
user_name = Faker::Name.first_name.downcase
user_password = Faker::Internet.password(min_length: 8)

user = create_user(name: user_name, login: user_name, password: user_password, password_confirmation: user_password, email: Faker::Internet.safe_email(name: user_name), is_admin: true)

p 'Making Project...'
project = create_project(title: team.name, team_id: team.id, user: user, description: '') 

p 'Making Team User...'
create_team_user(team: team, user: user, role: 'admin')

p 'Making Medias...'
link_media_link = 'https://meedan.com/post/nawa-newsroom-2022-journalism-students-explore-disinformation-open-source-verification-tools-and-media-monitoring'

claim_media = create_claim_media(user_id: user.id, quote: Faker::Quotes::Shakespeare.hamlet_quote)
link_media = Link.create!(user_id: user.id, url: link_media_link)
audio_media = UploadedAudio.create!(user_id: user.id, file: File.open(File.join(Rails.root, 'test', 'data', 'rails.mp3')))
image_media = UploadedImage.create!(user_id: user.id, file: File.open(File.join(Rails.root, 'test', 'data', 'rails.png')))
video_media = UploadedVideo.create!(user_id: user.id, file: File.open(File.join(Rails.root, 'test', 'data', 'rails.mp4')))

[claim_media, link_media, audio_media, image_media, video_media].each { |claim_type| ProjectMedia.create!(user_id: user.id, project: project, team: team, media: claim_type) }

p 'Making claim description and fact_check...'
project_media = ProjectMedia.create!(project: project, team: team, media: Blank.create!)
fact_check_link ='https://meedan.com/post/meedan-launches-collaborative-effort-to-address-misinformation-on-whatsapp-during-brazils-presidential-election'

claim_description = ClaimDescription.create!(description: Faker::Lorem.paragraph(sentence_count: 10), context: Faker::Lorem.sentence, user: user, project_media: project_media)
fact_check_media = create_fact_check(summary: Faker::Company.catch_phrase, url: fact_check_link, title: Faker::Company.name, user: user, claim_description: claim_description)

p 'Making Relationship...'

# ['Garlic can help you fight covid', 'Garlic can help you fight covid', 'Tea with garlic is a covid treatment', 'Tea with garlic is a covid treatment', Faker::Quotes::Shakespeare.hamlet_quote]

# claims
claim_media_1 = create_claim_media(user_id: user.id, quote: 'Garlic can help you fight covid')
claim_media_2 = create_claim_media(user_id: user.id, quote: 'Garlic can help you fight covid')
claim_media_3 = create_claim_media(user_id: user.id, quote: 'Tea with garlic is a covid treatment')
claim_media_4 = create_claim_media(user_id: user.id, quote: 'Tea is a great covid treatment')

project_media_1 = ProjectMedia.create!(user_id: user.id, project: project, team: team, media: claim_media_1) 
project_media_2 = ProjectMedia.create!(user_id: user.id, project: project, team: team, media: claim_media_2) 
project_media_3 = ProjectMedia.create!(user_id: user.id, project: project, team: team, media: claim_media_3) 
project_media_4 = ProjectMedia.create!(user_id: user.id, project: project, team: team, media: claim_media_4) 

create_relationship(source_id: project_media_1.id, target_id: project_media_2.id, relationship_type: Relationship.confirmed_type)
create_relationship(source_id: project_media_3.id, target_id: project_media_4.id, relationship_type: Relationship.suggested_type)

# images
image_media_1 = UploadedImage.create!(user_id: user.id, file: File.open(File.join(Rails.root, 'test', 'data', 'rails.png')))
image_media_2 = UploadedImage.create!(user_id: user.id, file: File.open(File.join(Rails.root, 'test', 'data', 'rails.png')))

project_media_5 = ProjectMedia.create!(user_id: user.id, project: project, team: team, media: image_media_1) 
project_media_6 = ProjectMedia.create!(user_id: user.id, project: project, team: team, media: image_media_2) 

create_relationship(source_id: project_media_5.id, target_id: project_media_6.id, relationship_type: Relationship.confirmed_type)

# audio
audio_media_1 = UploadedAudio.create!(user_id: user.id, file: File.open(File.join(Rails.root, 'test', 'data', 'rails.mp3')))
audio_media_2 = UploadedAudio.create!(user_id: user.id, file: File.open(File.join(Rails.root, 'test', 'data', 'rails.mp3')))

project_media_7 = ProjectMedia.create!(user_id: user.id, project: project, team: team, media: audio_media_1) 
project_media_8 = ProjectMedia.create!(user_id: user.id, project: project, team: team, media: audio_media_2) 

create_relationship(source_id: project_media_7.id, target_id: project_media_8.id)


p "Created — user: #{user_name} — email: #{user.email} — password : #{user_password}"
