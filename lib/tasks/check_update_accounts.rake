@accounts = 0
@sources = 0
@conditions = []

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
      condition.merge!({ key => value })
    end
    @conditions << condition
  end
end

def select_accounts
  accounts = []
  Embed.where(annotation_type: 'embed', annotated_type: 'Account').find_each do |e|
    embed = JSON.parse(e.embed)
    match = false
    @conditions.each do |c|
      c.each do |key, value|
        match = embed[key] == value
        break unless match
      end
      break if match
      match = false
    end
    accounts << e.annotated if match || @conditions.empty?
  end
  puts "#{accounts.size} accounts matched the criteria: #{@conditions.inspect}"
  accounts
end

def update_account(account, update_source = false)
  max_attempts = 3
  attempts = 0
  begin
    account.validate_pender_result(true)
  rescue Net::ReadTimeout
    attempts += 1
    puts "Failed to update account #{account.url}, attempt #{attempts}/#{max_attempts}"
    retry if attempts < max_attempts
  end
  if !account.pender_data.nil? && account.pender_data['error'].nil?
    account.set_pender_result_as_annotation
    @accounts += 1
    update_related_source(account) if update_source
  end
end

def update_related_source(account)
  account.sources.each do |source|
    source.name = account.data['author_name']
    source.avatar = account.data['author_picture']
    source.slogan = account.data['description'].to_s
    source.save!
    @sources += 1
  end
end

namespace :check do

  # bundle exec rake check:update_accounts['provider:facebook&subtype:page','provider:instagram','provider:youtube&subtype:channel']
  desc "update accounts that match some criteria"
  task :update_accounts => :environment do |t, args|
    parse_conditions args.extras, t.name
    select_accounts.each do |account|
     update_account account
    end
    puts "#{@accounts} accounts were changed."
  end

  # bundle exec rake check:update_accounts_and_sources['provider:facebook&subtype:page','provider:instagram','provider:youtube&subtype:channel']
  desc "update accounts that match some criteria and sources related"
  task :update_accounts_and_sources => :environment do |t, args|
    parse_conditions args.extras, t.name
    select_accounts.each do |account|
     update_account account, true
    end
    puts "#{@accounts} accounts were changed and #{@sources} sources were changed."
  end
end
