@accounts = 0
@sources = 0
@conditions = []
@updated_accounts = []
@failed_accounts = []

#[{"provider"=>"facebook", "subtype"=>"page"},{"provider"=>"instagram"},{"provider"=>"youtube", "sybtype => channel"}]
def parse_conditions(args, task_name)
  abort "E: usage: `rake #{task_name}['key:value&other_key:value2','key:value3','key:value4&other_value:value5']`.
  Example: `rake #{task_name}['provider:facebook&subtype:page','provider:instagram','provider:youtube&subtype:channel']`" if args.empty?

  args.each do |a|
    arg = a.split('&')
    return @conditions if arg.size == 1 && arg.first == 'all'
    condition = {}
    arg.each do |pair|
      key, value = pair.split(':')
      value = nil if value == 'nil'
      condition.merge!({ key => value })
    end
    @conditions << condition
  end
end

def match_conditions(data)
  match = false
  @conditions.each do |c|
    c.each do |key, value|
      match = data[key] == value
      break unless match
    end
    break if match
    match = false
  end
  match
end

def select_embeds
  accounts = []
  Embed.where(annotation_type: 'embed', annotated_type: 'Account').find_each do |e|
    embed = JSON.parse(e.embed)
    if match_conditions(embed) || @conditions.empty?
      accounts << e.annotated
    end
  end
  puts "#{accounts.size} accounts matched the criteria: #{@conditions.inspect}"
  accounts
end

def select_accounts(condition)
  accounts = []
  Account.find_each do |a|
   data = a.data
   if (match_conditions(data) || @conditions.empty?) && send(condition, data)
      accounts << a
    end
  end
  puts "#{accounts.size} accounts match the criteria"
  accounts
end

def without_data(data)
  data.empty?
end

def with_errors_on_data(data)
  !data['error'].nil?
end

def update_pender_data(account)
  max_attempts = 3
  attempts = 0
  begin
    account.validate_pender_result(true)
  rescue Net::ReadTimeout
    attempts += 1
    puts "Failed to update account #{account.url}, attempt #{attempts}/#{max_attempts}"
    retry if attempts < max_attempts
    if attempts < max_attempts
      retry
    else
      @failed_accounts << account.url
    end
  end
  account
end

def update_account(account, update_source = false)
  a = update_pender_data(account)
  if !a.pender_data.nil? && a.pender_data['error'].nil?
    a.set_pender_result_as_annotation
    @accounts += 1
    update_related_source(a) if update_source
  end
end

def update_related_source(account)
  data = account.data
  account.sources.each do |source|
    source.update_from_pender_data(data)
    source.save!
    @sources += 1
  end
end

def update_account_embed_with_user_omniauth_data(account)
  auth_info = account.user.omniauth_info if account.user
  if auth_info
    data = account.data
    data['username'] = auth_info['info']['name'] if auth_info['info']['name']
    data['title'] = auth_info['info']['name'] if auth_info['info']['name']
    data['picture'] = auth_info['info']['image'] if auth_info['info']['image']
    data['author_url'] = auth_info['url'] if auth_info['url']
    data['author_picture'] = auth_info['info']['image'] if auth_info['info']['image']
    data['author_name'] = auth_info['info']['name'] if auth_info['info']['name']

    em = account.pender_embed
    em.embed = data.to_json
    em.save!
    @accounts += 1
  end
end

def update_account_url(account)
  url = account.url
  a = update_pender_data account
  if !a.pender_data.nil? && a.pender_data['error'].nil?
    update_account_url_and_relations(account, a.url) if a.url != url
  else
    @failed_accounts << url
  end
end

def update_account_url_and_relations(account, new_url)
  url = account.url
  existing = Account.find_by_url(new_url)
  if existing.nil?
    account.update_columns(url: new_url)
  else
    Media.where(account_id: account.id).update_all(account_id: existing.id)
    AccountSource.where(account_id: account.id).update_all(account_id: existing.id)
    account.destroy
  end
  @updated_accounts << "#{url} => #{new_url}"
end

def log_to_file(filename, content, situation)
  File.open(filename, "w+") do |f|
    f.puts(content)
  end
  puts "The #{situation} accounts were saved on #{filename}"
end

def file_to_hashes(filename)
  urls = IO.readlines(filename).map(&:chomp)
  mapping = {}
  urls.each do |m|
    original, updated = m.split(' => ')
    mapping[original] = updated
  end
  mapping
end

def print_output
  puts "\n======================================================="
  if !@failed_accounts.empty?
    puts "#{@failed_accounts.size} failed accounts:"
    puts @failed_accounts
  end
  log_to_file('updated-accounts.txt', @updated_accounts, 'Updated')
  log_to_file('failed-accounts.txt', @failed_accounts, 'Failed')
end

namespace :check do

  # bundle exec rake check:update_accounts_through_embed['provider:facebook&subtype:page','provider:instagram','provider:youtube&subtype:channel']
  desc "update accounts when embed match some criteria"
  task :update_accounts_through_embed => :environment do |t, args|
    parse_conditions args.extras, t.name
    select_embeds.each do |account|
     update_account account
    end
    puts "#{@accounts} accounts were changed."
  end

  # bundle exec rake check:update_accounts_and_sources_through_embed['provider:facebook&subtype:page','provider:instagram','provider:youtube&subtype:channel']
  desc "update accounts when embed match some criteria and sources related"
  task :update_accounts_and_sources_through_embed => :environment do |t, args|
    parse_conditions args.extras, t.name
    select_embeds.each do |account|
     update_account account, true
    end
    puts "#{@accounts} accounts were changed and #{@sources} sources were changed."
  end

  # bundle exec rake check:update_accounts_without_data
  desc "update accounts without data"
  task :update_accounts_without_data => :environment do |t, args|
    parse_conditions args.extras, t.name
    select_accounts('without_data').each do |account|
     update_account account
    end
    puts "#{@accounts} accounts were changed."
  end

  # bundle exec rake check:update_accounts_with_errors_on_data['provider:facebook&type:profile']
  desc "update accounts with errors on data"
  task :update_accounts_with_errors_on_data => :environment do |t, args|
    parse_conditions args.extras, t.name
    select_accounts('with_errors_on_data').each do |account|
      update_account account
      print '.'
    end
    puts "#{@accounts} accounts were changed."
  end

  # bundle exec rake check:update_account_embed_with_user_omniauth_data['provider:facebook&type:profile']
  desc "update account embed with the related user omniauth data"
  task :update_account_embed_with_user_omniauth_data => :environment do |t, args|
    parse_conditions args.extras, t.name
    select_accounts('with_errors_on_data').each do |account|
      update_account_embed_with_user_omniauth_data(account)
      print '.'
    end
    puts "#{@accounts} accounts were changed."
  end

  # bundle exec rake check:update_all_accounts
  desc "update all accounts where url returned by Pender is different"
  task :update_all_accounts => :environment do |t|
    Account.find_each do |account|
      print '.'
      begin
        update_account_url(account)
      rescue
        @failed_accounts << account.url
      end
    end
    print_output
  end

  # bundle exec rake check:update_accounts_from_file[filename]
  # format of lines on file `<old url> => <new url>``
  desc "update accounts listed on a file"
  task :update_accounts_from_file => :environment do |t, args|
    mapping = file_to_hashes(args.extras.first)
    mapping.each do |original, updated|
      account = Account.find_by_url(original)
      next if account.nil?
      begin
        update_account_url_and_relations(account, updated)
        print '.'
      rescue
        @failed_accounts << account.url
      end
    end
    print_output
  end

end
