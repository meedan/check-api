# Join model
class ExplainerItem < ApplicationRecord
  include CheckPusher

  has_paper_trail on: [:create, :destroy], ignore: [:updated_at, :created_at], if: proc { |_x| User.current.present? }, versions: { class_name: 'Version' }

  belongs_to :explainer
  belongs_to :project_media

  validates_presence_of :explainer, :project_media
  validate :same_team
  validate :cant_apply_article_to_item_if_article_is_in_the_trash

  after_create :log_relevant_article_results
  after_commit :update_elasticsearch_data

  def version_metadata(_changes)
    { explainer_title: self.explainer.title }.to_json
  end

  def send_explainers_to_previous_requests(range)
    ids = ProjectMedia.where(id: self.project_media.related_items_ids).pluck(:id) # Including child items
    # Keep track of UIDs so we don't send the same explainer to the same user more than once.
    # We could use GROUP BY or DISTINCT ON, but it would be more complex for the average number of requests we have.
    uids = []
    TiplineRequest.no_articles_sent(ids).where(created_at: Time.now.ago(range.days)..Time.now).find_each do |tipline_request|
      uid = tipline_request.tipline_user_uid
      next if uids.include?(uid)
      uids << uid
      Bot::Smooch.delay_for(1.second, { queue: 'smooch_priority', retry: 0 }).send_explainer_to_user(self.id, tipline_request.id)
    end
  end

  private

  def same_team
    errors.add(:base, I18n.t(:explainer_and_item_must_be_from_the_same_team)) unless self.explainer&.team_id == self.project_media&.team_id
  end

  def cant_apply_article_to_item_if_article_is_in_the_trash
    errors.add(:base, I18n.t(:cant_apply_article_to_item_if_article_is_in_the_trash)) if self.explainer&.trashed
  end

  def update_elasticsearch_data
    return if self.disable_es_callbacks || RequestStore.store[:disable_es_callbacks]
    pm = self.project_media
    # touch item to update `updated_at` date
    if ProjectMedia.exists?(pm.id)
      updated_at = Time.now
      pm.update_columns(updated_at: updated_at)
      data = { updated_at: updated_at.utc }
      data['explainer_title'] = {
        method: "explainers_titles",
        klass: pm.class.name,
        id: pm.id,
        default: nil,
      }
      pm.update_elasticsearch_doc(data.keys, data, pm.id, true)
    end
  end

  def log_relevant_article_results
    ex = self.explainer
    self.project_media.delay.log_relevant_results(ex.class.name, ex.id, User.current&.id, self.class.actor_session_id)
  end
end
