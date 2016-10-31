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

  # TODO ask Caio for help with this, I've spent far too long on it
  desc "lookup a user for any given login, email, or part of a name"
  task :lookup, [:find] => [:environment] do |t, args|
      u = User.where("login ILIKE ?", args.find)      
      if u
         puts "found login for #{args.find}"
#         puts "#{u}"
         puts "#{u}"
#         puts "#{u.login}"
         
#         puts u.class
          u.each do |x| puts x end 
#         users.each do |x| puts x.inspect end 
#      else
      end
  end
end
