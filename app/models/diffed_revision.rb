# Wraps around an instance of `PaperTrail::Version` (where event==update) and
# lets us show a diff
class DiffedRevision

  def initialize(revision, record)
    raise 'undiffable revision' unless revision.event == 'update'
    @revision = revision
    @record   = record
  end

  def diff
    @diff ||= Differ.diff_by_line(
                after[content_attribute],
                before_content
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

  private

  def before
    # Version#object is the state of the object *before* the change was made.
    @before ||= YAML.load(@revision.object, permitted_classes: [ActiveSupport::TimeWithZone, Time, ActiveSupport::TimeZone], aliases: true)
  end

  def before_content
    harmonized_version = before[content_attribute].include?("\r\n") ? before[content_attribute] : before[content_attribute].gsub("\n", "\r\n")
    @revision.previous.event == 'create' ? harmonized_version : before[content_attribute]
  end

  def after
    # Note: PaperTrail::Version#object will return `nil` if its event type
    # is `create` - but in theory, @revision.next below should always return
    # a version with event type 'update' or 'destroy'. If it doesn't, and
    # this method crashes, then bad data has snuck into your DB somehow.
    @after ||= if next_revision = @revision.next
                 YAML.load(next_revision.object, permitted_classes: [ActiveSupport::TimeWithZone, Time, ActiveSupport::TimeZone], aliases: true)
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
