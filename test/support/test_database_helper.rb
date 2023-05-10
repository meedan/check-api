class TestDatabaseHelper
  class << self
    def setup_database_partitions!
      begin
        Version.create_infrastructure
        Version.create_new_partition_tables([0])
      rescue
        puts "Partitions already enabled. Continuing..."
      end
    end
  end
end
