class CreatePartitions < ActiveRecord::Migration
  def change
    Version.create_infrastructure
    Version.create_new_partition_tables([0])
    ids = Version.partition_generate_range(Team.first.id, Team.last.id)
    Version.create_new_partition_tables(ids)
  end
end
