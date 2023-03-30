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
# link_media_link = 'https://meedan.com/post/exploring-the-use-of-offline-games-for-media-literacy-and-misinformation-education'
link_media_link = 'https://meedan.com/post/meedan-partner-fatabyyano-launches-tipline-for-earthquake-crisis-response'

claim_media = create_claim_media(user_id: user.id, quote: Faker::Quotes::Shakespeare.hamlet_quote)
link_media = Link.create!(user_id: user.id, url: link_media_link)
audio_media = UploadedAudio.create!(user_id: user.id, file: File.open(File.join(Rails.root, 'test', 'data', 'rails.mp3')))
image_media = UploadedImage.create!(user_id: user.id, file: File.open(File.join(Rails.root, 'test', 'data', 'rails.png')))
video_media = UploadedVideo.create!(user_id: user.id, file: File.open(File.join(Rails.root, 'test', 'data', 'rails.mp4')))

[claim_media, link_media, audio_media, image_media, video_media].each { |claim_type| create_project_media(user_id: user.id, project: project, team: team, media: claim_type) }

p "Created — user: #{user_name} — email: #{user.email} — password : #{user_password}"

# create claims
# create fact-checks
project_media = ProjectMedia.create!(project: project, team: team, media: Blank.create!)
# fact_check_link = 'https://meedan.com/post/op-ed-heres-what-were-considering-in-the-lead-up-to-the-supreme-courts-decisions-on-the-future-of-the-internet'
fact_check_link = 'https://meedan.com/post/meedan-impact-story-using-ai-to-investigate-weapons-trafficking-and-human-rights-violations'

claim_description = ClaimDescription.create!(description: Faker::Lorem.paragraph(sentence_count: 10), context: Faker::Lorem.sentence, user: user, project_media: project_media)
fact_check_media = create_fact_check(summary: Faker::Company.catch_phrase, url: fact_check_link, title: Faker::Company.name, user: user, claim_description: claim_description)