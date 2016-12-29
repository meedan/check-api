require 'yaml'
namespace :check do
   desc "clean private data from the database"
   task cleandb: :environment do
     Team.all.each do |t|
       t.set_slack_notifications_enabled('0');
       t.set_slack_webhook('nothing');
       t.save(validate: false)
     end
     User.all.each do |u|
       u.update_columns(email: '', encrypted_password: 'deleted', settings: '')
     end
     Project.all.each do |p|
       p.update_column(:settings, '')
     end
   end
end
