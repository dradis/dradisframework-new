class TasksController < AuthenticatedController
  include ProjectScoped
  layout 'tylium'
  def index; end
end
