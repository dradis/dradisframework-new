class IssuesController < AuthenticatedController
  include ActivityTracking
  include ConflictResolver
  include ContentFromTemplate
  include DynamicFieldNamesCacher
  include IssuesHelper
  include LiquidEnabledResource
  include Mentioned
  include MultipleDestroy
  include NotificationsReader
  include ProjectScoped
  include Publishable

  before_action :set_issuelib
  before_action :set_issues, except: [:destroy]
  before_action :set_columns, only: :index

  before_action :set_or_initialize_issue, except: [:import, :index]
  before_action :set_auto_save_key, only: [:new, :create, :edit, :update]
  before_action :set_affected_nodes, only: [:show]
  before_action :set_form_cancel_path, only: [:new, :edit]
  before_action :set_tags, except: [:destroy]

  def index
  end

  def show
    @affected_nodes = Node.joins(:evidence)
                        .select('nodes.id, label, type_id, count(evidence.id) as evidence_count, nodes.updated_at')
                        .where('evidence.issue_id = ?', @issue.id)
                        .group('nodes.id')
                        .sort_by { |node, _| node.label }

    @first_node      = @affected_nodes.first
    @first_evidence  = Evidence.where(node: @first_node, issue: @issue)

    load_conflicting_revisions(@issue)
  end

  def new
    # See ContentFromTemplate concern
    @issue.text = template_content if params[:template]
  end

  def create
    @issue.author = current_user.email

    respond_to do |format|
      if @issue.save &&
          # FIXME: need to fix Taggable concern.
          #
          # For some reason we can't save the :tags before we save the model,
          # so first we save it, then we apply the tags.
          #
          # See #set_or_initialize_issue()
          #
          @issue.update(issue_params)

        track_created(@issue)

        # Only after we save the issue, we can create valid taggings (w/ valid
        # taggable IDs)
        @issue.tag_from_field_content!

        format.html { redirect_to [current_project, @issue], notice: 'Issue added.' }
      else
        format.html do
          flash.now[:alert] = 'Issue couldn\'t be added.'
          render :new
        end
      end
      format.js
    end
  end

  def edit
    @form_preview_path = preview_project_issue_path(current_project, @issue)
  end

  def update
    respond_to do |format|
      updated_at_before_save = @issue.updated_at.to_i

      if @issue.update(issue_params)
        @modified = true
        check_for_edit_conflicts(@issue, updated_at_before_save)
        track_updated(@issue)
        format.html { redirect_to_main_or_qa }
      else
        format.html do
          flash.now[:alert] = 'Issue couldn\'t be updated.'
          render :edit
        end
      end
      format.js
      format.json
    end
  end

  def destroy
    respond_to do |format|
      if @issue.destroy
        track_destroyed(@issue)
        format.html { redirect_to project_issues_path(current_project), notice: 'Issue deleted.' }
        format.json
      else
        format.html { redirect_to project_issues_path(current_project), notice: "Error while deleting issue: #{@issue.errors}" }
        format.json
      end
    end
  end

  def import
    importer = IssueImporter.new(params)
    results = importer.query
    @import_issues = issues_from_import_records(results)

    @plugin = importer.plugin
    @filter = importer.filter
    @query = params[:query]

    @default_columns = ['Title', 'Tags']
    @all_columns = @default_columns | (@import_issues.map(&:fields).map(&:keys).uniq.flatten - ['AddonTags'])
  end

  private

  def liquid_resource_assigns
    { 'issue' => IssueDrop.new(@issue) }
  end

  def redirect_to_main_or_qa
    notice = 'Issue updated.'

    if params[:return_to] == 'qa'
      if @issue.ready_for_review?
        redirect_to project_qa_issue_path(current_project, @issue), notice: notice
      else
        redirect_to project_qa_issues_path(current_project), notice: notice
      end
    else
      redirect_to project_issue_path(current_project, @issue), notice: notice
    end
  end

  def set_affected_nodes
    @affected_nodes = Node.joins(:evidence)
                          .select('nodes.id, label, type_id, count(evidence.id) as evidence_count, nodes.updated_at')
                          .where('evidence.issue_id = ?', @issue.id)
                          .group('nodes.id')
                          .sort_by { |node, _| node.label }
  end

  def set_form_cancel_path
    @form_cancel_path = @issue.new_record? ? project_issues_path(current_project) : [current_project, @issue]
  end

  def set_columns
    default_field_names = ['Title', 'Tags', 'Affected', 'State'].freeze
    extra_field_names = ['Created', 'Created by', 'Updated'].freeze

    dynamic_fields = dynamic_field_names(@unsorted_issues)

    rtp = current_project.report_template_properties
    rtp_default_fields = rtp ? rtp.issue_fields.default.field_names : []

    @default_columns = rtp_default_fields.presence || default_field_names
    @all_columns = default_field_names | rtp_default_fields | dynamic_fields | extra_field_names
  end

  def set_issues
    # We need a transaction because multiple DELETE calls can be issued from
    # index and a TOCTOR can appear between the Note read and the Issue.find
    Note.transaction do
      @unsorted_issues = Issue.where(node_id: @issuelib.id).select(
        'notes.id, notes.author, notes.text, notes.state, '\
        'count(evidence.id) as affected_count, notes.created_at, notes.updated_at'
      ).
      joins('LEFT OUTER JOIN evidence on notes.id = evidence.issue_id').
      group('notes.id').
      includes(:affected, :tags)

      @issues = @unsorted_issues.sort
    end
  end

  def set_issuelib
    @issuelib = current_project.issue_library
  end

  # Once a valid @issuelib is set by the previous filter we look for the Issue we
  # are going to be working with based on the :id passed by the user.
  def set_or_initialize_issue
    if params[:id]
      @issue = current_project.issues.find(params[:id])
    elsif params[:issue]
      @issue = Issue.new(issue_params.except(:tag_list)) do |i|
        i.node = @issuelib
      end
    else
      @issue = Issue.new(node: @issuelib)
    end
  end

  def set_tags
    @tags = current_project.tags
  end

  def issue_params
    params.require(:issue).permit(:state, :tag_list, :text)
  end

  def set_auto_save_key
    @auto_save_key = if @issue&.persisted?
      "issue-#{@issue.id}"
    elsif params[:template]
      "project-#{current_project.id}-issue-#{params[:template]}"
    else
      "project-#{current_project.id}-issue"
    end
  end
end
