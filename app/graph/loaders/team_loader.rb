module Loaders
  class TeamLoader < GraphQL::Batch::Loader
    def perform(team_ids)
      Team.where(id: team_ids).each do |team|
        fulfill(team.id, team)
      end

      team_ids.each do |id|
        fulfill(id, nil) unless fulfilled?(id)
      end
    end
  end
end