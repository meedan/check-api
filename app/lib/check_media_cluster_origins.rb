module CheckMediaClusterOrigins
  class OriginCodes
    TIPLINE_SUBMITTED = 0
    USER_ADDED = 1
    USER_MERGED = 2
    USER_MATCHED = 3
    AUTO_MATCHED = 4
    ALL = [TIPLINE_SUBMITTED, USER_ADDED, USER_MERGED, USER_MATCHED, AUTO_MATCHED]

    def self.all_origins
      {
        'TIPLINE_SUBMITTED' => TIPLINE_SUBMITTED, # First media of a cluster, submitted through a tipline
        'USER_ADDED' => USER_ADDED, # First media of a cluster, uploaded manually using Check Web
        'USER_MERGED' => USER_MERGED, # When a user manually-creates a relationship
        'USER_MATCHED' => USER_MATCHED, # When a user confirms a suggestion
        'AUTO_MATCHED' => AUTO_MATCHED # When a bot creates a relationship
      }
    end
  end
end
