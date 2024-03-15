class CheckClusterCenter

  def self.replace_or_keep_cluster_center(current_center, new_pm)
    return new_pm.id if current_center.nil?
    # Define passed variable to contain items that passed check
    # Based on `passed` values we should return the id or go to next check
    # i.e passed is empty or passed contains two items means we should go to next check otherwise
    # passed contaion one item (length == 1) return the id 

    # Check #1: Fact-check
    passed = []
    passed << current_center.id if ['paused', 'published'].include?(current_center.report_status)
    passed << new_pm.id if ['paused', 'published'].include?(new_pm.report_status)
    return passed.first if passed.length == 1
    # Check #2: Has a claim?
    passed = ClaimDescription.where(project_media_id: [current_center.id, new_pm.id])
    return passed.first.project_media_id if passed.length == 1
    # Check #3: Most number of requests
    passed = []
    if (current_center.requests_count != 0 || new_pm.requests_count != 0) && current_center.requests_count != new_pm.requests_count
      id = current_center.requests_count > new_pm.requests_count ? current_center.id : new_pm.id
      passed << id
    end
    return passed.first if passed.length == 1
    # Check #4: Most recently Last updated
    passed = []
    if current_center.updated_at != new_pm.updated_at
      id = current_center.updated_at > new_pm.updated_at ? current_center.id : new_pm.id
      passed << id
    end
    return passed.first if passed.length == 1
    # Check #5: Alphabetical team name
    first_team = [current_center.team_name, new_pm.team_name].sort.first
    current_center.team_name == first_team ? current_center.id : new_pm.id
  end
end 