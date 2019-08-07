require 'benchmark'

def api_keys_query(table)
  "SELECT #{table}.*
   FROM #{table}
   INNER JOIN
     users ON users.api_key_id = #{table}.id
   WHERE
     users.id IN (#{get_ids('users')})"
end

def dynamic_annotation_annotation_types_query(table, field = '*')
  "SELECT #{table}.#{field} FROM #{table}"
end

def dynamic_annotation_field_instances_query(table)
  "SELECT #{table}.* FROM #{table}"
end

def dynamic_annotation_field_types_query(table)
  "SELECT #{table}.* FROM #{table}"
end

def teams_query(table, field = '*')
  "SELECT #{table}.#{field} FROM #{table} WHERE id=#{@id}"
end

def accounts_query(table, field = '*')
  "SELECT #{table}.#{field} FROM #{table} WHERE team_id=#{@id}"
end

def contacts_query(table)
  "SELECT #{table}.* FROM #{table} WHERE team_id=#{@id}"
end

def projects_query(table, field = '*')
  "SELECT #{table}.#{field} FROM projects WHERE team_id=#{@id}"
end

def sources_query(table, field = '*')
  "SELECT #{table}.#{field} FROM sources WHERE team_id=#{@id} OR (sources.user_id IN (#{get_ids('users')})) OR team_id IS NULL"
end

def tag_texts_query(table)
  "SELECT #{table}.* FROM #{table} WHERE team_id=#{@id}"
end

def team_tasks_query(table)
  "SELECT #{table}.* FROM #{table} WHERE team_id=#{@id}"
end

def team_users_query(table, field = '*')
  "SELECT #{table}.#{field} FROM #{table} WHERE team_id=#{@id}"
end

def account_sources_query(table, field = '*')
  "SELECT #{table}.#{field}
   FROM #{table}
   WHERE
     #{table}.source_id IN (#{get_ids('sources')})"
end

def project_medias_query(table, field = '*')
  "SELECT #{table}.#{field}
   FROM #{table}
   WHERE
     #{table}.project_id IN (#{get_ids('projects')})"
end

def project_sources_query(table, field = '*')
  "SELECT #{table}.#{field}
   FROM #{table}
   WHERE
     #{table}.project_id IN (#{get_ids('projects')})"
end

def users_query(table, field = '*')
  users_from_team_query(table, field) + ' UNION ' + users_outside_team_query(table, field)
end

def users_from_team_query(table, field = '*')
  "SELECT #{table}.#{field}
   FROM #{table}
   WHERE
     #{table}.id IN (#{get_ids('team_users', 'user_id')})"
end

def users_outside_team_query(table, field = '*')
  query = "SELECT DISTINCT #{table}.#{field}
   FROM #{table}
   INNER JOIN
     project_medias ON project_medias.user_id = #{table}.id AND project_medias.id IN (#{get_ids('project_medias')})
   WHERE
     #{table}.id NOT IN (#{get_ids('team_users', 'user_id')})"
  return query unless field == '*'
  temp_table = "users_outside#{@id}"
  conn = ActiveRecord::Base.connection
  conn.execute("CREATE TEMP TABLE #{temp_table} AS #{query}")
  conn.execute("UPDATE #{temp_table} SET name = 'Anonymous', login = 'Anonymous', token = 'invalid_token', email = NULL, source_id = NULL")
  "SELECT #{temp_table}.#{field}
   FROM #{temp_table}"
end

def medias_query(table, field = '*')
  "SELECT #{table}.#{field}
   FROM #{table}
   INNER JOIN
     project_medias ON project_medias.media_id = #{table}.id
   WHERE
     project_medias.id IN (#{get_ids('project_medias')})"
end

def claim_sources_query(table, field = '*')
  "SELECT #{table}.#{field}
   FROM #{table}
   WHERE
     #{table}.source_id IN (#{get_ids('sources')})"
end

def relationships_query(table, field = '*')
  "SELECT #{table}.#{field}
   FROM #{table}
   WHERE
     #{table}.source_id IN (#{get_ids('project_medias')})"
end

def annotations_query(table, field = '*', annotation_type = nil, annotated_type = nil)
  annotated_types = annotated_type.nil? ? ['accounts', 'sources', 'medias', 'project_medias', 'project_sources'] : [annotated_type]
  unions = []
  annotated_types.each do |annotated_table|
    unions << "SELECT a.#{field} FROM #{table} a WHERE a.annotated_type = '#{annotated_table.classify}' AND a.annotated_id IN (#{get_ids(annotated_table)})"
    copy_to_file(unions.last, "#{table}_#{annotated_table}", table) if field == '*'
  end
  unions << send('annotations_tasks_query', 'annotations', field)
  copy_to_file(unions.last, "#{table}_tasks", table) if field == '*'
  unions.join(' UNION ')
end

def annotations_tasks_query(table, field = '*')
  "SELECT a.#{field}
   FROM #{table} a, #{table} t
   WHERE
     a.annotated_id = t.id AND a.annotated_type = 'Task' AND t.annotated_type = 'ProjectMedia' AND t.annotated_id IN (#{get_ids('project_medias')})"
end

def bounces_query(table, field = '*')
  "SELECT #{table}.#{field}
   FROM #{table}
   INNER JOIN
     users ON users.email = #{table}.email
   WHERE
     users.id IN (#{get_ids('users')})"
end

def assignments_query(table, field = '*')
  "SELECT #{table}.#{field}
   FROM #{table}
   WHERE
     #{table}.user_id IN (#{get_ids('users')})"
end

def dynamic_annotation_fields_query(table, field = '*')
  "SELECT #{table}.#{field}
   FROM #{table}
   WHERE
     #{table}.annotation_id IN (#{get_ids('annotations')})"
end

def login_activities_query(table, field = '*')
  "SELECT #{table}.#{field}
   FROM #{table}
   WHERE
     #{table}.user_id IN (#{get_ids('users')})"
end

def versions_query(table)
  mapping = {
    'dynamic_annotation_fields': 'DynamicAnnotation::Field',
    'accounts': 'Account',
    'assignments': 'Assignment',
    'medias': 'Media',
    'project_medias': 'ProjectMedia',
    'project_sources': 'ProjectSource',
    'projects': 'Project',
    'relationships': 'Relationship',
    'sources': 'Source'
  }

  mapping.each_pair do |item_table, item_type|
    select_query = "SELECT #{table}.* FROM #{table} WHERE #{table}.item_type='#{item_type}' AND CAST(#{table}.item_id AS INTEGER) IN (#{get_ids(item_table)})"
    copy_to_file(select_query, "#{table}_#{item_table}", table)
  end

  types = (get_annotation_types - get_dynamic_annotation_types).map(&:capitalize).push("'Dynamic'")
  select_query = "SELECT #{table}.* FROM #{table} WHERE #{table}.item_type IN (#{types.join(',')}) AND CAST(#{table}.item_id AS INTEGER) IN (#{get_ids('annotations')})"
  copy_to_file(select_query, "#{table}_annotations", table)

  select_query = "SELECT #{table}.* FROM #{table} WHERE #{table}.item_type='Team' AND #{table}.item_id='#{@id}'"
  copy_to_file(select_query, "#{table}_teams", table)
end

def get_dynamic_annotation_types
  query = "SELECT DISTINCT(annotation_type) FROM dynamic_annotation_annotation_types"
  @dynamic_types ||= ActiveRecord::Base.connection.execute(query).values.map {|v| "'#{v[0]}'" }
end

def get_annotation_types
  query = "SELECT DISTINCT(annotation_type) FROM annotations"
  @annotation_types ||= ActiveRecord::Base.connection.execute(query).values.map {|v| "'#{v[0]}'" }
end

def get_ids(table, field = 'id')
  query = send("#{table}_query", table, field)
  if instance_variable_get("@#{table}_#{field}s").nil?
    ids = ActiveRecord::Base.connection.execute(query).values.map {|v| v[0] }.concat(['-1']).join(',')
    instance_variable_set("@#{table}_#{field}s", ids)
  end
  instance_variable_get("@#{table}_#{field}s")
end

def count(query)
  count_query = query.gsub(/SELECT (.*) FROM/, 'SELECT COUNT(\1) FROM')
  values = ActiveRecord::Base.connection.execute(count_query).values
  values.empty? ? 0 : values.first[0].to_i
end

def primary_key(table)
  mapping = {
    dynamic_annotation_annotation_types: 'annotation_type',
    dynamic_annotation_field_instances: 'name',
    dynamic_annotation_field_types: 'field_type'
  }
  mapping.dig(table.to_sym) || 'id'
end

def tmp_folder_path
  return @tmp_folder_path unless @tmp_folder_path.nil?
  dir = File.join(Rails.root, 'tmp')
  Dir.mkdir(dir) unless File.exist?(dir)

  foldername = @id.to_s + '_' + Digest::MD5.hexdigest([@id, Time.now.to_i.to_s].join('_')).reverse
  folder = File.join(dir, foldername)
  Dir.mkdir(folder) unless File.exist?(folder)
  @tmp_folder_path = folder
end

def copy_to_file(select_query, filename, table)
  filename += '.copy'
  begin
    filepath = File.join(tmp_folder_path, filename)
    @files[filename] = filepath
    total = count(select_query)
    offset = 0
    limit = 1000
    puts "Generating #{filename}..."
    while offset <= total do
      paginated_query = select_query + " ORDER BY #{primary_key(table)} ASC LIMIT #{limit} OFFSET #{offset}"
      query = "COPY (#{paginated_query}) TO STDOUT NULL '*' CSV"
      query += " HEADER" if offset.zero?
      offset += limit
      print "#{offset}/#{total}\r"
      $stdout.flush
      csv = []
      conn = ActiveRecord::Base.connection.raw_connection
      conn.copy_data(query) do
        while row = conn.get_copy_data
          csv.push(row)
        end
      end
      File.open(filepath, 'a') do |file|
        file.write(csv.join("").force_encoding("UTF-8"))
      end
    end

  rescue Exception => e
    Rails.logger.warn "[Team Export] Could not create #{filename}: #{e.message} #{e.backtrace.join("\n")}"
  end
end

def dump_filepath(slug)
  dir = File.join(Rails.root, 'public', 'team_dump')
  Dir.mkdir(dir) unless File.exist?(dir)

  filename = slug + '_' + Digest::MD5.hexdigest([slug, Time.now.to_i.to_s].join('_')).reverse
  File.join(dir, filename + '.zip')
end

def export_zip(slug)
  require 'zip'
  dump_password = SecureRandom.hex
  buffer = Zip::OutputStream.write_buffer(::StringIO.new(''), Zip::TraditionalEncrypter.new(dump_password)) do |out|
    @files.each do |filename, filepath|
      out.put_next_entry(filename)
      out.write File.read(filepath)
    end
  end
  buffer.rewind
  filename = dump_filepath(slug)
  File.write(filename, buffer.read)
  [filename, dump_password]
end

namespace :check do
  # bundle exec rake check:export_team['team_slug','email@example.com','versions:users']
  desc "export the data of a team to files"
  task :export_team, [:team, :email, :except] => :environment do |t, args|
    team = if args.team.to_i > 0
             Team.find_by_id args.team
           else
             Team.find_by_slug args.team
           end
    return "Could not find a team with id or slug #{args.team}" if team.nil?
    slug, @id = team.slug, team.id
    email = args.email
    exceptions = args.except ? args.except.split(':') : []
    puts "Skipping: #{exceptions}" unless exceptions.empty?
    tables = ActiveRecord::Base.connection.tables - exceptions
    puts "Dumping #{tables.size} tables."
    @files ||= {}
    tables.each do |table|
      query = "#{table}_query"
      begin
        if self.respond_to?(query, table)
            if ['versions', 'annotations'].include?(table)
              send(query, table)
            else
              copy_to_file(send(query, table), table, table)
            end
            ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS users_outside#{@id};") if table == 'users'
        else
          puts "Missing query to copy #{table}"
        end
      rescue Exception => e
        puts "Error dumping table #{table}: #{e.inspect}"
      end
    end
    filename, password = export_zip(slug)
    FileUtils.remove_dir(tmp_folder_path, true) if File.exist?(tmp_folder_path)
    puts "#{filename}: #{password}"
    AdminMailer.delay.send_team_download_link(slug, filename, email, password) unless email.blank?
  end

  def table(name)
    if name.match(/annotations_(.*)/)
      'annotations'
    elsif name.match(/versions_(.*)/)
      'versions'
    else
      name
    end
  end

  desc "import team files to database"
  task :import_team, [:folder_path] => :environment do |t, args|
    @path = args.folder_path
    conn = ActiveRecord::Base.connection
    tables = conn.tables
    Benchmark.bm(40) do |bm|
      Dir.foreach(args.folder_path).each do |filename|
        copy = filename.match(/(.*).copy/)
        next unless copy
        table_name = table(copy[1])
        bm.report("#{table_name}: #{filename}") do
          conn.execute("COPY #{table_name} FROM '/tmp/#{@path}/#{filename}' NULL '*' CSV HEADER")
        end
      end
    end
  end
end
