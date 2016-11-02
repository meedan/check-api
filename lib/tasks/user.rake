require 'yaml'
namespace :user do

  desc "reset users password user:passreset['login','password']"
  task :passreset, [:login, :pass] => [:environment] do |t, args|
      user = User.where(:login => args.login).first      
      if user
        user.password = args.pass
        user.password_confirmation = args.pass
        user.save
        puts "updated password for #{user.login}"
      else
        puts "#{args.login} not found"        
      end  
  end

  # TODO allow for passing an id for simple lookup
  desc "lookup a user for any given login, email, or part of a name"
  task :lookup, [:find] => [:environment] do |t, args|
      puts "Args were: #{args}"
      find = args[:find]
      users = User.where("name ILIKE (?) OR uuid LIKE (?) OR email LIKE (?) OR login LIKE (?)", "%#{find}%", "%#{find}%", "%#{find}%", "%#{find}%")
      if users
         puts "report: id name login uuid email provider omniauth"          
         users.each do |u|
            puts "found: #{u.id} #{u.name} #{u.login} #{u.email} '#{u.provider}' '#{u.omniauth_info}'"
            teams = TeamUser.where(user_id: u.id).map(&:team)
            if teams
               teams.each do |t|
                  puts "   team: #{t.id} #{t.name} #{t.subdomain}"
               end
            else
               puts "user is not in a team"               
            end                      
         end
      else
         puts "not found"
      end
  end
end
