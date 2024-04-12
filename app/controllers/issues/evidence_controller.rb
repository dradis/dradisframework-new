class Issues::EvidenceController < AuthenticatedController
  include ActivityTracking
  include ContentFromTemplate
  include DynamicFieldNamesCacher
  include LiquidEnabledResource
  include MultipleDestroy
  include ProjectScoped

  before_action :set_issues, only: [:create_multiple, :index, :new]
  before_action :set_affected_nodes, only: :index
  before_action :set_auto_save_key, only: :new
  before_action :set_columns, only: :index

  def index
    render layout: false
  end

  def new
    @nodes_for_add_evidence = current_project.nodes.user_nodes.order(:label)

    @template_content = template_content if params[:template]
  end

  def create_multiple
    # validate Issue
    @issue = current_project.issues.find(evidence_params[:issue_id])

    if node_params_empty?
      @content = evidence_params[:content]
      @nodes_for_add_evidence = current_project.nodes.user_nodes.order(:label)

      flash.now[:alert] = 'A node must be selected.'
      return render :new
    end

    if params[:evidence][:node_ids]
      params[:evidence][:node_ids].reject(&:blank?).each do |node_id|
        node = current_project.nodes.find(node_id)
        evidence = Evidence.create!(
          author: current_user.email,
          content: evidence_params[:content],
          issue_id: @issue.id,
          node_id: node.id
        )
        track_created(evidence)
      end
    end

    if params[:evidence][:node_list]
      if params[:evidence][:node_list_parent_id].present?
        parent = current_project.nodes.find(params[:evidence][:node_list_parent_id])
      end
      params[:evidence][:node_list].lines.map(&:strip).reject(&:blank?).each do |label|
        unless (node = current_project.nodes.find_by(label: label))
          node = current_project.nodes.create!(
            type_id: Node::Types::HOST,
            label: label,
            parent: parent,
          )
          track_created(node)
        end

        evidence = Evidence.create!(
          author: current_user.email,
          content: evidence_params[:content],
          issue_id: @issue.id,
          node_id: node.id
        )
        track_created(evidence)
      end
    end

    redirect_to project_issue_path(current_project, evidence_params[:issue_id], tab: 'evidence-tab'), notice: 'Evidence added for selected nodes.'
  end

  private

  def evidence_params
    params.require(:evidence).permit(:author, :content, :issue_id, :node_id)
  end

  def node_params_empty?
    params[:evidence][:node_list].blank? &&
      (params[:evidence][:node_ids].reject(&:empty?).empty?)
  end

  def set_columns
    default_field_names = ['Label', 'Title'].freeze
    extra_field_names = ['Created', 'Created by', 'Updated'].freeze

    dynamic_fields = dynamic_field_names(@issue.evidence)

    rtp = current_project.report_template_properties
    rtp_default_fields = rtp ? rtp.evidence_fields.default.field_names : []

    @default_columns = rtp_default_fields.presence || default_field_names
    @all_columns = rtp_default_fields | dynamic_fields | extra_field_names
  end

  def set_affected_nodes
    @affected_nodes = Node.joins(:evidence)
                          .select('nodes.id, label, type_id, count(evidence.id) as evidence_count, nodes.updated_at')
                          .where('evidence.issue_id = ?', @issue.id)
                          .group('nodes.id')
                          .sort_by { |node, _| node.label }
  end

  def set_auto_save_key
    @auto_save_key =  if params[:template]
      "issue-#{params[:issue_id]}-evidence-#{params[:template]}"
    elsif params[:from_rtp]
      "issue-#{params[:issue_id]}-rtp-evidence"
    else
      "issue-#{params[:issue_id]}-evidence"
    end
  end

  def set_issues
    @issues = current_project.issues.order(:text)
    @issue = @issues.find(params[:issue_id]) if params[:issue_id]
  end
end
