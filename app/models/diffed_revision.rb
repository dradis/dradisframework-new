# Wraps around an instance of `PaperTrail::Version` (where event==update) and
# lets us show a diff
class DiffedRevision
  def initialize(revision, record)
    raise 'undiffable revision' unless revision.event == 'update'
    @revision = revision
    @record   = record
  end

  def diff
    @diff ||=
      Differ.diff(
        after[content_attribute].gsub(/\r/, ''),
        before[content_attribute].gsub(/\r/, ''),
        /(\s)/
      )
  end

  def last_updated_at
    before['updated_at'].strftime(RevisionsHelper::DATE_FORMAT)
  end

  def previous_action
    @revision.previous.event
  end

  def previous_author
    @revision.previous.whodunnit
  end

  def this_author
    @revision.whodunnit
  end

  def updated_at
    after['updated_at'].strftime(RevisionsHelper::DATE_FORMAT)
  end

  def changed_state
    return {} unless @record.respond_to?(:state)

    # Cast the ['state'] attribute as it can be both the state index (0,1,2) or
    # the state name.
    before_state = @record.class.new(state: before['state']).state
    after_state = @record.class.new(state: after['state']).state

    if before_state != after_state
      { after: after_state, before: before_state }
    else
      {}
    end
  end

  private

  def before
    # Version#object is the state of the object *before* the change was made.
    @before ||= YAML.load(@revision.object, permitted_classes: [ActiveSupport::TimeWithZone, ActiveSupport::TimeZone, Date, Time], aliases: true)
  end

  def after
    # Note: PaperTrail::Version#object will return `nil` if its event type
    # is `create` - but in theory, @revision.next below should always return
    # a version with event type 'update' or 'destroy'. If it doesn't, and
    # this method crashes, then bad data has snuck into your DB somehow.
    @after ||=
      if next_revision = @revision.next
        YAML.load(next_revision.object, permitted_classes: [ActiveSupport::TimeWithZone, ActiveSupport::TimeZone, Date, Time], aliases: true)
      else
        @record.attributes
      end
  end

  # Issue/Note have the `text` attribute aliased as `content` but we can't use
  # it here because 1) the saved object does not use the aliased method and
  # 2) the #attributes method does not return the aliased method.
  def content_attribute
    case @record
    when Card; 'description'
    when Issue, Note; 'text' # FIXME - ISSUE/NOTE INHERITANCE
    when Evidence; 'content'
    end
  end
end
