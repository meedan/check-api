class CreateAccountsForSlackUsers < ActiveRecord::Migration
  def change
    n = 0
    m = 0
    User.where(provider: 'slack').each do |u|
      begin
        info = u.omniauth_info['extra']['raw_info']
        url = info['url'] + 'team/' + info['user']
        account = Account.new
        account.user = u
        account.source = u.source
        account.url = url
        account.skip_pender = true
        account.save!
        n += 1
      rescue
        m += 1
      end
    end
    puts "#{n} users updated, #{m} users skipped"
  end
end
