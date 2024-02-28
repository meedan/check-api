require File.expand_path('../../config/environment', __FILE__)

puts "Enter the team slug:"
print ">> "
slug = STDIN.gets.chomp

puts "Enter the csv file name:"
print ">> "
csv_file = STDIN.gets.chomp

puts "Enter the custom mapping if needed (if not, press enter):"
print ">> "
custom_mapping = STDIN.gets.chomp
status_mapping = custom_mapping ? custom_mapping : { 'undetermined' => 'undetermined' }

ActiveRecord::Base.logger = nil
team = Team.find_by_slug(slug)
user = BotUser.fetch_user
User.current = user
Team.current = team

begin
  s3_client = Aws::S3::Client.new(region: 'eu-west-1')
rescue Aws::Sigv4::Errors::MissingCredentialsError
  puts "Please provide the AWS credentials."
  exit 1
end

bucket_name = "meedan-fact-check-imports-#{ENV["DEPLOY_ENV"]}"
path = "#{csv_file}.csv"
data = s3_client.get_object(bucket: bucket_name, key: path)
n = data.size

# Make sure that the data is valid
data.each_with_index do |row, i|
  raise "Blank cell in line #{i + 1}" if row['Title'].blank? || row['Link'].blank? || row['Text'].blank?
  raise "No URL found in line #{i + 1}" unless row['Link'] =~ /^http/
end

i = 0
data.each do |row|
  i += 1
  title = row['Title']
  link = row['Link']
  text = row['Text']
  rating = 'undetermined'
  language = 'en'
  claim_review = {
    identifier: "#{file}-#{i}",
    author: team.name,
    author_link: "https://checkmedia.org/#{slug}",
    claimReviewed: '',
    headline: title,
    text: text,
    reviewRating: {
      alternateName: rating
    },
    url: link,
    service: slug,
    raw: {
      language: language
    }
  }
  Bot::Fetch::Import.import_claim_review(JSON.parse(claim_review.to_json), team.id, user.id, 'undetermined', status_mapping, true, false)

  puts "[#{Time.now}] Imported row #{i}/#{n}"
end
