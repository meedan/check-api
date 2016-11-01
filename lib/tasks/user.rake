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

  desc "lookup a user for any given login, email, or part of a name"
  task :lookup, [:find] => [:environment] do |t, args|
      puts "Args were: #{args}"
      find = args[:find]
      users = User.where("name ILIKE (?) OR email LIKE (?) OR login LIKE (?)", "%#{find}%", "%#{find}%", "%#{find}%")
      if users
         puts "report: id login name email"          
         users.each do |u|
            puts "found: #{u.id} #{u.login} #{u.name} #{u.email}"          
         end
      else
         puts "not found"
      end
  end
end
