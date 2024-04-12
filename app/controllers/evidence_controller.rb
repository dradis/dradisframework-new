class EvidenceController < NestedNodeResourceController
  include ConflictResolver
  include EvidenceHelper
  include LiquidEnabledResource
  include Mentioned
  include MultipleDestroy
  include NodesSidebar
  include NotificationsReader
  include ProjectScoped

  before_action :set_or_initialize_evidence, except: [ :index, :create_multiple ]
  before_action :initialize_nodes_sidebar, only: [ :edit, :new, :show ]
  skip_before_action :find_or_initialize_node, only: [:create_multiple]
  before_action :set_auto_save_key, only: [:new, :create, :edit, :update]

  def show
    @issue = @evidence.issue

    load_conflicting_revisions(@evidence)
  end

  def new
    # See ContentFromTemplate concern
    @evidence.content = template_content if params[:template]
  end

  def create
    @evidence.author = current_user.email
    autogenerate_issue if evidence_params[:issue_id].blank?

    respond_to do |format|
      if @evidence.save
        track_created(@evidence)
        format.html {
          redirect_to [current_project, @evidence.node, @evidence],
            notice: "Evidence added for node #{@evidence.node.label}."
        }
      else
        format.html {
          initialize_nodes_sidebar
          render 'new'
        }
      end
      format.js
    end
  end

  def edit
    @form_preview_path = preview_project_node_evidence_path(current_project, @node, @evidence)
  end

  def update
    respond_to do |format|
      updated_at_before_save = @evidence.updated_at.to_i

      @evidence.assign_attributes(evidence_params)
      autogenerate_issue if evidence_params[:issue_id].blank?

      if @evidence.save
        track_updated(@evidence)
        check_for_edit_conflicts(@evidence, updated_at_before_save)
        format.html do
          redirect_to evidence_redirect_path(params[:return_to]), notice: 'Evidence updated.'
        end

      else
        format.html {
          initialize_nodes_sidebar
          render 'edit'
        }
      end
      format.js
    end
  end

  def destroy
    respond_to do |format|
      if @evidence.destroy
        track_destroyed(@evidence)
        format.html {
          notice = "Successfully deleted evidence for '#{@evidence.issue.title}.'"
          # Evidence can be deleted from 3 places:
          # 1. from the issue evidence tab
          # 2. from the node evidence tab
          # 3. from the evidence show page itself (under node)
          # When using redirect_back in case 3, we find an evidence not found error,
          # since the evidence does not exist anymore. That's why we check the 'Referer' here:
          if request.headers['Referer'] == project_node_evidence_url(current_project, @node, @evidence)
            redirect_to project_node_path(current_project, @node), notice: notice
          else
            redirect_back fallback_location: project_node_path(current_project, @node), notice: notice
          end
        }
        format.js
      else
        format.html {
          redirect_to [current_project, @node, @evidence],
            notice: "Error while deleting evidence: #{@evidence.errors}"
        }
        format.js
      end
    end
  end

  private

  def autogenerate_issue
    @evidence.issue = Issue.autogenerate_from(@evidence)
    track_created(@evidence.issue)
  end

  def liquid_resource_assigns
    {
      'evidence' => EvidenceDrop.new(@evidence),
      'node' => NodeDrop.new(@evidence.node)
    }
  end

  # Look for the Evidence we are going to be working with based on the :id
  # passed by the user.
  def set_or_initialize_evidence
    if params[:id]
      @evidence = @node.evidence.includes(:issue, issue: [:tags]).find(params[:id])
    elsif params[:evidence]
      @evidence = Evidence.new(evidence_params) do |e|
        e.node = @node
      end
    else
      @evidence = Evidence.new(node: @node)
    end
  end

  def evidence_params
    params.require(:evidence).permit(:author, :content, :issue_id, :node_id)
  end

  def set_auto_save_key
    @auto_save_key =  if @evidence&.persisted?
      "evidence-#{@evidence.id}"
    elsif params[:template]
      "node-#{@node.id}-evidence-#{params[:template]}"
    else
      "node-#{@node.id}-evidence"
    end
  end
end
