class PublicTeam < Team
  # Override this function because FileUploader.store_dir depends on class name.
  def avatar
    self.becomes(Team).avatar
  end
end
