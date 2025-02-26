class Activity < ApplicationRecord
  ACTIVITIES_STRFTIME_FORMAT = '%A, %B %-e %Y'.freeze

  # -- Relationships --------------------------------------------------------

  belongs_to :trackable, polymorphic: true, required: false
  belongs_to :user

  def project=(new_project); end

  # NOTE: when the project importer creates activities, it will try to match
  # them to existing users based on the 'user email' field in the XML. If it
  # can't find any users with the given address, it will save user_id as '-1'.
  # So if you're seeing Activities in your DB with that user_id, this is why.

  # -- Validations ----------------------------------------------------------

  validates_presence_of :action, :trackable_id, :trackable_type, :user

  VALID_ACTIONS = %w[create destroy recover state_change update]

  validates_inclusion_of :action, in: VALID_ACTIONS

  # -- Scopes ---------------------------------------------------------------

  scope :latest, -> do
    includes(:trackable).order('activities.created_at DESC').limit(10)
  end

  # -- Callbacks ------------------------------------------------------------

  # Cast action to a string so the 'inclusion' validation works with symbols
  before_validation { self.action = action.to_s if action.present? }

  # -- Class Methods -----------------------------------------------------

  # -- Instance Methods -----------------------------------------------------

  # Because Issue descends from Note but doesn't use STI, Rails's default
  # polymorphic setter will set 'trackable_type' to 'Note' when you pass an
  # Issue to trackable. This means when you load the Activity later then
  # trackable will return the wrong class. Override the default behaviour here
  # for issues:
  #
  # FIXME - ISSUE/NOTE INHERITANCE
  def trackable=(new_trackable)
    super
    self.trackable_type = 'Issue' if new_trackable.is_a?(Issue)
    new_trackable
  end

  def to_xml(xml_builder, version: 3)
    xml_builder.action(action)
    xml_builder.user_email(user.email)
    xml_builder.created_at(created_at.to_i)
  end
end
