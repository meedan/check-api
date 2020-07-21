require 'benchmark'
require 'sqlite3'

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
  "SELECT #{table}.#{field} FROM #{table} WHERE id=#{@team.id}"
end

def accounts_query(table, field = '*')
  "SELECT #{table}.#{field} FROM #{table} WHERE team_id=#{@team.id}"
end

def contacts_query(table)
  "SELECT #{table}.* FROM #{table} WHERE team_id=#{@team.id}"
end

def projects_query(table, field = '*')
  "SELECT #{table}.#{field} FROM projects WHERE team_id=#{@team.id}"
end

def sources_query(table, field = '*')
  "SELECT #{table}.#{field} FROM sources WHERE team_id=#{@team.id} OR (sources.user_id IN (#{get_ids('users')})) OR team_id IS NULL"
end

def tag_texts_query(table)
  "SELECT #{table}.* FROM #{table} WHERE team_id=#{@team.id}"
end

def team_tasks_query(table)
  "SELECT #{table}.* FROM #{table} WHERE team_id=#{@team.id}"
end

def team_users_query(table, field = '*')
  "SELECT #{table}.#{field} FROM #{table} WHERE team_id=#{@team.id}"
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
   WHERE #{table}.team_id=#{@team.id}"
end

def project_media_projects_query(table, field = '*')
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
  temp_table = "users_outside_#{@team.id}"
  conn = ActiveRecord::Base.connection
  conn.execute("CREATE TEMP TABLE #{temp_table} AS #{query}")
  conn.execute("UPDATE #{temp_table} SET name = 'Redacted', login = 'redacted', token = NULL, email = NULL, source_id = NULL")
  "SELECT #{temp_table}.#{field} FROM #{temp_table}"
end

def medias_query(table, field = '*')
  "SELECT #{table}.#{field}
   FROM #{table}
   INNER JOIN
     project_medias ON project_medias.media_id = #{table}.id
   WHERE
     project_medias.id IN (#{get_ids('project_medias')})"
end

def relationships_query(table, field = '*')
  "SELECT #{table}.#{field}
   FROM #{table}
   WHERE
     #{table}.source_id IN (#{get_ids('project_medias')})"
end

def annotations_query(table, field = '*')
  annotated_types = ['accounts', 'sources', 'medias', 'project_medias']
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

def versions_query(table, field = '*')
  "SELECT #{table}.#{field} FROM #{table}_partitions.p#{@team.id} #{table}"
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

def primary_key(table)
  mapping = {
    dynamic_annotation_annotation_types: 'annotation_type',
    dynamic_annotation_field_instances: 'name',
    dynamic_annotation_field_types: 'field_type'
  }
  mapping.dig(table.to_sym) || 'id'
end

def dump_filepath
  File.join(Dir.tmpdir, @team.slug + '_' + Digest::MD5.hexdigest([@team.slug, Time.now.to_i.to_s].join('_')).reverse)
end

def tmp_folder_path
  return @tmp_folder_path unless @tmp_folder_path.nil?
  folder = dump_filepath
  FileUtils.mkdir_p(folder)
  @tmp_folder_path = folder
end

def copy_to_file(select_query, filename, table)
  filename += '.csv'
  @progressbar.log "Export #{filename}"
  @progressbar.increment
  begin
    filepath = File.join(tmp_folder_path, filename)
    @files[filename] = filepath
    query = "COPY (#{select_query}) TO STDOUT CSV HEADER"
    conn = ActiveRecord::Base.connection.raw_connection
    File.open(filepath, 'wb') do |file|
      conn.copy_data(query) do
        while chunk = conn.get_copy_data
          file.write(chunk)
        end
      end
    end
  rescue Exception => e
    raise "Error creating #{filename}: #{e.message}"
  end
end

def export_zip
  require 'zip'
  zipfile = dump_filepath + '.zip'
  password = SecureRandom.hex
  Zip::File.open(zipfile, Zip::TraditionalEncrypter.new(password)) do |out|
    @files.each do |filename, filepath|
      @progressbar.log "Zip #{filename}"
      @progressbar.increment
      out.add(filename, filepath)
    end
  end
  puts "#{zipfile}: #{password}"
end

namespace :check do
  namespace :data do
    desc "Export workspace data to files"
    task :export_team, [:team] => :environment do |task, args|
      # Get team id from passed option
      raise "Usage: #{task.to_s}[team id or slug, exceptions... (optional)]" unless args.team
      @team = if args.team.to_i > 0
        Team.find_by_id args.team
      else
        Team.find_by_slug args.team
      end
      exceptions = args.extras + [
        "pghero_query_stats",
        "schema_migrations",
        "shortened_urls",
        "claim_sources",
        "project_sources"
      ]
      tables = ActiveRecord::Base.connection.tables - exceptions
      # total = tables + csv files + 4 additional tables for annotations
      @progressbar = ProgressBar.create(:total => (tables.count + 4) * 2)
      @files ||= {}
      tables.each do |table|
        query = "#{table}_query"
        begin
          if self.respond_to?(query, table)
            if table == "annotations"
              send(query, table)
            else
              copy_to_file(send(query, table), table, table)
            end
          else
            raise "Missing query to copy #{table}"
          end
        rescue Exception => e
          raise "Error dumping table #{table}: #{e.message}"
        end
        begin
          ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS users_outside_#{@team.id};") if table == 'users'
        rescue Exception => e
        end
      end
      export_zip
      FileUtils.remove_dir(@tmp_folder_path, true) if File.exist?(@tmp_folder_path)
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
  end
end
