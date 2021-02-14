# :nocov:
require 'benchmark'
require 'sqlite3'
require 'tempfile'

module PgExport
  module InQ
    extend ActiveRecord::ConnectionAdapters::PostgreSQL::Quoting
  end

  module OutQ
    # Rails 4: there's no ActiveRecord::ConnectionAdapters::SQLite3::Quoting
    # so we make it up
    def self.quote_column_name(name)
      %Q("#{name.to_s.gsub('"', '""')}")
    end

    def self.quote_table_name(name)
      quote_column_name(name)
    end
  end

  class PGTextDecoderISO8601Timestamp < PG::SimpleDecoder
    def decode(value, tuple=nil, field=nil)
      value.tr(' ', 'T') << 'Z'
    end
  end

  module TableStrategies
    class Base
      attr_reader(:team_id)

      def initialize(team_id)
        @team_id = team_id
      end

      # Returns a SELECT clause for selecting the whole table
      def select_sql
        columns = wanted_active_record_columns.map do |column|
          clause = override_field_select_sql(column)
          quoted_column_name = InQ.quote_column_name(column.name)
          if clause.nil?
            quoted_column_name
          else
            "#{clause} AS #{quoted_column_name}"
          end
        end

        "SELECT #{columns.join(', ')} FROM #{InQ.quote_table_name(pg_table_name)} #{where_clause}"
      end

      # Returns partial-SQL string. If it isn't empty, it should start with "WHERE"
      def where_clause
        ""
      end

      def copy_to_sqlite3_database(db)
        db.execute(define_sqlite3_table_sql())
        copy_data_to_sqlite3(db)
      end

      # Table name that we will write in the SQLite3 script
      def table_name
        self.class.name.demodulize.tableize
      end

      protected

      def all_active_record_columns
        ActiveRecord::Base.connection.columns(pg_table_name)
      end

      # If non-nil, make it a Set: a whitelist of names we want.
      def wanted_column_names
        nil  # nil => select all columns
      end

      def wanted_active_record_columns
        all = all_active_record_columns
        filter = wanted_column_names
        if filter.nil?
          all
        else
          ret = all.select { |column| filter.include?(column.name) }
          unhandled_column_names = (filter - ret.map(&:name)).to_a.sort
          if unhandled_column_names.size > 0
            raise "Script/data discrepancy: columns #{unhandled_column_names} do not exist in table #{pg_table_name}"
          end
          ret
        end
      end

      def define_sqlite3_table_sql()
        columns = wanted_active_record_columns
        lines = []
        lines << "CREATE TABLE #{table_name} ("
        lines.concat(columns.map{|column| "  #{define_sqlite3_column(column)},"})
        lines << "  PRIMARY KEY (#{model_class.primary_key})"
        lines << ");"
        lines.join("\n")
      end

      def copy_data_to_sqlite3(db)
        conn = ActiveRecord::Base.connection
        columns = wanted_active_record_columns
        pg_conn = conn.raw_connection
        decode = PG::TextDecoder::CopyRow.new(type_map: build_pg_copy_rows_type_map(columns))

        db.transaction do
          statement = db.prepare <<-SQL
            INSERT INTO #{OutQ.quote_table_name(table_name)}
              (#{columns.map{ |col| OutQ.quote_column_name(col.name) }.join(', ')})
            VALUES (#{columns.map{'?'}.join(', ')})
          SQL
          pg_conn.copy_data("COPY (#{select_sql}) TO STDOUT", decode) do
            while row = pg_conn.get_copy_data
              result_set = statement.execute(row.map!{|v| sqlite3_encode_value(v)})
            end
          end
          statement.close()
        end
      end

      # Returns a value to replace _all_ values in the column in question.
      #
      # For instance: 'NULL' means, "all values are NULL". Or
      # "CASE foo WHEN 1 THEN x ELSE y END" means more complex logic.
      def override_field_select_sql(column)
        nil
      end

      # Table name we will read from the Postgres database
      def pg_table_name
        table_name
      end

      # ActiveRecord model we're dumping
      def model_class
        table_name.classify.constantize
      end

      # SQL query (to be used as subquery) for user IDs that are either members of
      # `team_id` or are outside collaborators.
      def user_ids_sql
        "#{member_user_ids_sql} UNION SELECT user_id FROM project_medias WHERE team_id = #{team_id}"
      end

      def member_user_ids_sql
        "SELECT user_id FROM team_users WHERE team_id = #{team_id} AND status = 'member'"
      end

      def select_ids_in_team
        "SELECT id FROM #{InQ.quote_table_name(pg_table_name)} #{where_clause}"
      end

      def define_sqlite3_column(column)
        name = column.name
        type = {
          integer: 'INTEGER',
          string: 'TEXT',
          datetime: 'ISO8601TEXT',
          text: 'TEXT',
          boolean: 'INTEGER',
          float: 'REAL',
          jsonb: 'JSONTEXT',
        }[column.type]
        null = if column.null then '' else ' NOT NULL' end
        "#{OutQ.quote_column_name(name)} #{type}#{null}"
      end

      def build_pg_copy_rows_type_map(columns)
        PG::TypeMapByColumn.new(
          columns.map do |column|
            {
              'integer': PG::TextDecoder::Integer.new,
              'string': PG::TextDecoder::String.new,
              'datetime': PGTextDecoderISO8601Timestamp.new,
              'text': PG::TextDecoder::String.new,
              'boolean': PG::TextDecoder::Boolean.new,
              'float': PG::TextDecoder::Float.new,
              'jsonb': PG::TextDecoder::String.new,
            }[column.type]
          end
        )
      end

      def sqlite3_encode_value(value)
        if true === value
          1
        elsif false === value
          0
        else
          value
        end
      end
    end

    class BotResource < Base
      def where_clause
        "WHERE team_id = #{team_id}"
      end
    end

    class DynamicAnnotationFieldInstance < Base
      # No WHERE clause: all teams see all fields
      protected

      def model_class
        DynamicAnnotation::FieldInstance
      end
    end

    class DynamicAnnotationFieldType < Base
      # No WHERE clause: all teams see all field types
      protected

      def model_class
        DynamicAnnotation::FieldType
      end
    end

    class DynamicAnnotationAnnotationType < Base
      # No WHERE clause: all teams see all annotation types
      protected

      def model_class
        DynamicAnnotation::AnnotationType
      end
    end

    class Team < Base
      def where_clause
        "WHERE id = #{team_id}"
      end
    end

    class Account < Base
      def where_clause
        "WHERE team_id = #{team_id}"
      end
    end

    class Contact < Base
      def where_clause
        "WHERE team_id = #{team_id}"
      end
    end

    class Project < Base
      def where_clause
        "WHERE team_id = #{team_id}"
      end
    end

    class Source < Base
      def where_clause
        "WHERE team_id = #{team_id} OR team_id IS NULL OR sources.user_id IN (#{user_ids_sql})"
      end
    end

    class TagText < Base
      def where_clause
        "WHERE team_id = #{team_id}"
      end
    end

    class TeamTask < Base
      def where_clause
        "WHERE team_id = #{team_id}"
      end
    end

    class TeamUser < Base
      def where_clause
        "WHERE team_id = #{team_id}"  # includes status <> 'member'
      end
    end

    class AccountSource < Base
      def where_clause
        source_ids_in_team_sql = Source.new(team_id).select_ids_in_team
        "WHERE source_id IN (#{source_ids_in_team_sql})"
      end
    end

    class ProjectMedia < Base
      def where_clause
        "WHERE team_id = #{team_id}"
      end
    end

    class ProjectMediaProject < Base
      def where_clause
        project_ids_in_team = Project.new(team_id).select_ids_in_team
        "WHERE project_id IN (#{project_ids_in_team})"
      end
    end

    class User < Base
      def where_clause
        "WHERE id IN (#{user_ids_sql})"
      end

      protected

      def override_field_select_sql(column)
        redacted = if column.null
          'NULL'
        elsif %i(date datetime time timestamp).include?(column.type)
          "'1970-01-01T00:00:00.000Z'"
        elsif %i(binary string text).include?(column.type)
          "'(redacted)'"
        else
          '0'
        end

        if (
          column.name == 'encrypted_password' or
          column.name =~ /(\A|_)otp(\Z|_)/ or # one-time password stuff
          column.name =~ /(\A|_)token(\Z|_)/ # auth tokens
        )
          # redact auth tokens for everybody, so crackers can't crask passwords
          redacted
        elsif (
          %w(encrypted_password email login login settings image source_id).include?(column.name) or
          column.name.end_with?('_at') or
          column.name.start_with?('cached_') or
          column.name.start_with?('current_')
        )
          # redact for non-members only, so teams can't export info on non-members
          "CASE WHEN id IN (#{member_user_ids_sql}) THEN #{InQ.quote_column_name(column.name)} ELSE #{redacted} END"
        else
          nil
        end
      end
    end

    class Media < Base
      def where_clause
        project_media_ids_in_team_sql = ProjectMedia.new(team_id).select_ids_in_team
        "WHERE id IN (SELECT media_id FROM project_medias WHERE id IN (#{project_media_ids_in_team_sql}))"
      end
    end

    class Relationship < Base
      def where_clause
        project_media_ids_in_team_sql = ProjectMedia.new(team_id).select_ids_in_team
        "WHERE source_id IN (#{project_media_ids_in_team_sql})"
      end
    end

    class Annotation < Base
      def where_clause
        project_media_ids_in_team_sql = ProjectMedia.new(team_id).select_ids_in_team
        bot_resource_ids_in_team_sql = BotResource.new(team_id).select_ids_in_team
        project_ids_in_team_sql = Project.new(team_id).select_ids_in_team
        account_ids_in_team_sql = Account.new(team_id).select_ids_in_team
        source_ids_in_team_sql = Source.new(team_id).select_ids_in_team
        media_ids_in_team_sql = Media.new(team_id).select_ids_in_team
        parts = [
          "annotated_type = 'Account' AND annotated_id IN (#{account_ids_in_team_sql})",
          "annotated_type = 'BotResource' AND annotated_id IN (#{bot_resource_ids_in_team_sql})",
          "annotated_type = 'Media' AND annotated_id IN (#{media_ids_in_team_sql})",
          "annotated_type = 'Project' AND annotated_id IN (#{project_ids_in_team_sql})",
          "annotated_type = 'ProjectMedia' AND annotated_id IN (#{project_media_ids_in_team_sql})",
          "annotated_type = 'Source' AND annotated_id IN (#{source_ids_in_team_sql})",
          "annotated_type = 'Task' AND annotated_id IN (SELECT id FROM annotations a2 WHERE annotations.annotated_id = a2.id AND a2.annotated_type = 'ProjectMedia' AND a2.annotated_id IN (#{project_media_ids_in_team_sql}))",
          "annotated_type = 'Team' AND annotated_id = #{team_id}",
        ]
        "WHERE (#{parts.join(') OR (')})"
      end
    end

    class Bounce < Base
      def where_clause
        "WHERE email IN (SELECT email FROM users WHERE id IN (#{user_ids_sql}))"
      end
    end

    class Assignment < Base
      def where_clause
        "WHERE user_id IN (#{user_ids_sql})"
      end
    end

    class DynamicAnnotationField < Base
      def where_clause
        annotation_ids_in_team_sql = Annotation.new(team_id).select_ids_in_team
        "WHERE annotation_id IN (#{annotation_ids_in_team_sql})"
      end

      protected

      def model_class
        DynamicAnnotation::Field
      end
    end

    class LoginActivity < Base
      def where_clause
        "WHERE user_id IN (#{user_ids_sql})"
      end
    end

    class Version < Base
      def where_clause
        "WHERE team_id = #{team_id}"
      end

      protected

      def wanted_column_names
        Set.new(%w(
          id
          item_type
          item_id
          event
          whodunnit
          object_changes
          created_at
          event_type
          associated_id
          associated_type
          team_id
        ))
      end

      def pg_table_name
        "versions_partitions.p#{team_id}"
      end
    end
  end

  def self.export_team_to_sqlite_lz4_file(team_slug, path)
    team = ::Team.find_by(slug: team_slug)
    if team.nil?
      raise "Could not find team with slug #{team_slug}"
    end
    team_id = team.id

    Tempfile.open('pg-export-team-to-sqlite3-lz4') do |sqlite_db_tempfile|
      sqlite_db_tempfile.close
      SQLite3::Database.new(':memory:') do |db|
        for klass in [
            TableStrategies::Account,
            TableStrategies::AccountSource,
            TableStrategies::Annotation,
            TableStrategies::Assignment,
            TableStrategies::BotResource,
            TableStrategies::Bounce,
            TableStrategies::Contact,
            TableStrategies::DynamicAnnotationAnnotationType,
            TableStrategies::DynamicAnnotationField,
            TableStrategies::DynamicAnnotationFieldInstance,
            TableStrategies::DynamicAnnotationFieldType,
            TableStrategies::LoginActivity,
            TableStrategies::Media,
            TableStrategies::Project,
            TableStrategies::ProjectMedia,
            TableStrategies::ProjectMediaProject,
            TableStrategies::Relationship,
            TableStrategies::Source,
            TableStrategies::TagText,
            TableStrategies::Team,
            TableStrategies::TeamTask,
            TableStrategies::TeamUser,
            TableStrategies::User,
            TableStrategies::Version,
        ]
          dumper = klass.new(team_id)
          puts "Reading #{team_slug}.#{dumper.table_name}..."
          dumper.copy_to_sqlite3_database(db)
        end

        puts "Writing #{sqlite_db_tempfile.path}..."
        # We _could_ use SQLite3::Database.new(filename) directly. But testing
        # this on 2020-07-23:
        #
        # time docker-compose exec api bundle exec rake check:data:export_team[boom-factcheck]
        #
        # gave these results:
        #
        # DIRECT TO FILE: 30.8s, 349MB (63MB gzipped)
        # MEMORY AND VACUUM: 26.5s, 327MB (54MB gzipped)
        #
        # So VACUUM INTO is 14% faster (or much more, if we ignore Rails init)
        # and 6% more space-efficient (or 14%, after compression)
        db.execute("VACUUM INTO '#{sqlite_db_tempfile.path}'")
      end

      # We compress for uploading to Workbench with LZ4 compression.
      #
      # Rationale: sqlite3 databases compress very well (~25% easy). We won't
      # send Workbench uncompressed data because that's overtaxing it. And we
      # won't send _gzipped_ data, because that would be slow to decompress.
      # Google Snappy fits a happy medium, but it isn't a file format. (Hadoop,
      # for instance, adds a framing format _on top of_ the Snappy format; but
      # we aren't using Hadoop libraries.)
      #
      # Lz4 has an official file format, and it behaves similarly to Snappy.
      # Bonus: it has a command-line tool, so ad-hoc commands are simpler.
      puts "Compressing #{path}..."
      puts `lz4 -f --favor-decSpeed #{sqlite_db_tempfile.path} #{path}`
      if not $?.success?
        raise "lz4 exited with code #{$?.exitstatus}"
      end
    end
  end
end
# :nocov:
