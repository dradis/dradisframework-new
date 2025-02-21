class ExportController < AuthenticatedController
  include ProjectScoped

  def index
    @default_button_state = non_draft_records? ? 'published' : 'all'
  end

  private

  def non_draft_records?
    issues = current_project.issues
    issues.published.or(issues.ready_for_review).any? || non_draft_records_pro
  end

  def non_draft_records_pro
    false
  end

  # In case something goes wrong with the export, fail graciously instead of
  # presenting the obscure Error 500 default page of Rails.
  def rescue_action(exception)
    flash[:error] = exception.message
    redirect_to project_upload_manager_path(current_project)
  end
end
