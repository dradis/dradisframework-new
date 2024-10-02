class ProjectsController < AuthenticatedController
  include NotificationsReader
  include TasksHelper

  before_action :set_project

  helper        :tylium
  helper_method :current_project
  layout        'tylium'

  def index
    redirect_to project_path(current_project)
  end

  def show
    @activities    = Activity.latest
    @authors       = [current_user]
    @boards        = current_project.methodology_library.boards
    @issues        = current_project.issues.includes(:tags).sort
    @methodologies = current_project.methodology_library.notes.map { |n| Methodology.new(filename: n.id, content: n.text) }
    @nodes         = current_project.nodes.in_tree
    @tags          = current_project.tags
    @tasks         = assigned_cards(current_project.id)

    @count_by_tag  = { unassigned: 0 }
    @issues_by_tag = Hash.new { |h, k| h[k] = [] }

    @tag_names = @tags.map do |tag|
      @count_by_tag[tag.name] = 0
      [tag.name, [tag.display_name, tag.color]]
    end.to_h

    @issues.each do |issue|
      if issue.tags.empty?
        @issues_by_tag[:unassigned] << issue
        @count_by_tag[:unassigned]  += 1
      else
        issue.tags.each do |tag|
          @issues_by_tag[tag.name] << issue
          @count_by_tag[tag.name]  += 1
        end
      end
    end

    respond_to do |format|
      format.html { render layout: 'tylium' if !request.xhr? }
      format.json { render json: @boards }
    end
  end

  private
  def set_project
    current_project
  end

  def current_project
    @current_project ||= Project.new
  end
end
