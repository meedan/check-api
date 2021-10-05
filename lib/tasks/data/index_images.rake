namespace :check do
  namespace :data do
    desc "Index all images in the Alegre similarity index"
    task :index_images => :environment do |task, args|
      # For all teams where Alegre bot is enabled, resend each image to Alegre
      bot = BotUser.find_by(:login => 'alegre')

      # Calculate total work to be done
      total = ApplicationRecord.connection.execute("
        select count(*) as total from
        project_medias pm
        left join medias m on m.id = pm.media_id
        left join team_users tu on tu.team_id = pm.team_id
        where tu.user_id = #{bot.id} and m.type = 'UploadedImage'
      ")[0]["total"].to_i

      progressbar = ProgressBar.create(:total => total)

      TeamBotInstallation.where(:user_id => bot.id).find_each do |tbi|
        ProjectMedia.where(:team_id => tbi.team_id).joins(:media).where('medias.type=?', 'UploadedImage').find_each do |pm|
          progressbar.increment
          similar = Bot::Alegre.request_api('get', '/image/similarity/', {
            context: {
              project_media_id: pm.id,
            }
          })
          if similar['result'].length == 0
            Bot::Alegre.send_to_media_similarity_index(pm)
          end
        end
      end
    end
  end
end
