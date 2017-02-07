require 'yaml'
namespace :check do
   namespace :project do
   
     desc "given an id, delete the associated project but not delete its reports project:delete[id]"
     task :delete, [:id] => [:environment] do |t, args|
         p = Project.where(id: args.id).last
         if p
            puts "project found: #{p.id} #{p.title} .. deleting project"
            ProjectMedia.find_by(project_id: args.id).each{ |pm| pm.destroy }
            p.destroy # Caio says m.destroy is better than m.delete
            puts "deleted: #{p.id} #{p.title}"
         else
           puts "project #{args.id} not found"        
         end  
     end
   
   end
end
