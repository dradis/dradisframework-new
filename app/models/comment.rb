class Comment < ApplicationRecord
  include Notifiable

  MENTION_PATTERN = /[a-z0-9][a-z0-9\-@\.]*/.freeze

  # -- Relationships --------------------------------------------------------
  belongs_to :commentable, polymorphic: true
  belongs_to :user, optional: true

  # -- Callbacks ------------------------------------------------------------
  after_create :create_subscription

  # -- Validations ----------------------------------------------------------
  validates :content, presence: true, length: { maximum: DB_MAX_TEXT_LENGTH }
  validates :commentable, presence: true, associated: true

  # -- Scopes ---------------------------------------------------------------

  # -- Class Methods --------------------------------------------------------

  # -- Instance Methods -----------------------------------------------------
  # Because Issue descends from Note but doesn't use STI, Rails's default
  # polymorphic setter will set 'commentable_type' to 'Note' when you pass an
  # Issue to commentable. This means when you load the Activity later then
  # commentable will return the wrong class. Override the default behaviour here
  # for issues:
  #
  # FIXME - ISSUE/NOTE INHERITANCE
  def commentable=(new_commentable)
    super
    self.commentable_type = 'Issue' if new_commentable.is_a?(Issue)
    new_commentable
  end

  def create_subscription
    Subscription.subscribe(user: user, to: commentable) if user
  end

  def notify(action:, actor:, recipients:)
    case action.to_s
    when 'create'
      subscribe_mentioned()
      create_notifications(action: :mention, actor: actor,  recipients: mentions)

      # We're finding subscribers that have not been mention here
      # using ActiveRecord because create_notifications expect recipients
      # to be an ActiveRecord::Relation.
      subscribers = User.includes(:subscriptions).where(
        subscriptions: { subscribable_id: commentable.id, subscribable_type: commentable.class.to_s }
      ).where.not(id: [user.id] + mentions.pluck(:id))
      subscribers = subscribers.select { |user| Ability.new(user).can?(:read, self) }
      create_notifications(action: :create, actor: actor, recipients: subscribers)
    end
  end

  def mentions
    @mentions = nil if content_changed?
    @mentions ||= begin
      emails = []
      HTML::Pipeline::MentionFilter.mentioned_logins_in(content, MENTION_PATTERN) do |_, login, _|
        emails << login
      end

      Comment.mentionable_users(commentable, User.where(email: emails.uniq))
    end
  end

  def self.mentionable_users(resource, extra_scope = nil)
    base_scope = User.enabled
    scope = extra_scope ? base_scope.merge(extra_scope) : base_scope

    if resource.is_a?(Project)
      scope.merge(resource.testers_for_mentions)
    elsif resource.respond_to?(:project)
      scope.merge(resource.project.testers_for_mentions)
    else
      ids = scope.select { |user|
        Ability.new(user).can?(:read, resource)
      }.map(&:id)

      # Ensure we return an ActiveRecord::Relation object
      scope.where(id: ids)
    end
  end

  def to_xml(xml_builder, version: 3)
    xml_builder.comment do |comment_builder|
      comment_builder.content do
        comment_builder.cdata!(content)
      end
      comment_builder.author(user.email)
      comment_builder.created_at(created_at.to_i)
    end
  end

  private

  def subscribe_mentioned
    mentions.each do |mention|
      Subscription.subscribe(user: mention, to: commentable)
    end
  end
end
