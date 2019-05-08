require 'optparse'

namespace :check do
  namespace :export do
    desc "List uploaded images for a given project"
    task images: :environment do
      # Get the project id.
      options = {}
      o = OptionParser.new
      o.banner = "Usage: rake #{ARGV[0]} -- options"
      o.on("--project=PROJECT-ID") { |project|
        options[:project] = project
      }
      args = o.order!(ARGV) {}
      o.parse!(args)

      # List the image paths.
      pms = ProjectMedia.where(:project_id => options[:project]).joins(:media).where('medias.type=?', 'UploadedImage')
      pms.each { |pm| puts(pm.media.file.file.file) }
    end
  end
end
