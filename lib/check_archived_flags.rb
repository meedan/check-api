module CheckArchivedFlags
  class FlagCodes
    NONE = 0 # Default, means that the item is visible in lists and "all items" and actionable (can be annotated)
    # All other values mean that the item is hidden and not actionable until reverted to zero
    TRASHED = 1 # When a user sends an item to the trash or when a rule action sends an item to a trash
    UNCONFIRMED = 2 # When the item is submitted by a tipline user without explicit confirmation
    PENDING_SIMILARITY_ANALYSIS = 3 # When an item is submitted throught the tipline but was not analyzed by the text similarity yet (Alegre Bot)... after similarity analysis, it goes back to zero
  end
end
