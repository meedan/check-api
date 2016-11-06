require 'yaml'
namespace :check do
   namespace :report do
   
     desc "given an id, delete the associated report report:delete[id]"
     task :delete, [:id] => [:environment] do |t, args|
         m = Media.where(id: args.id).last
         if m
            puts "report found: #{m.id} #{m.url} .. deleting report and all annotations"
            if m.annotations
               puts "deleting annotations"
               m.annotations.each{ |a| a.destroy }
            end
            if m.project_medias
               puts "deleting medias"
               m.project_medias.each{ |a| a.destroy }
            end
            m.destroy  # Caio says m.destroy is better than m.delete
            puts "deleted: #{m.id} #{m.url}"
         else
           puts "media #{args.id} not found"        
         end  
     end
   
   end
end
