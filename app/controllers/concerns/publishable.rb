module Publishable
  extend ActiveSupport::Concern

  included do
    before_action :ensure_reviewer, only: [:create, :update, :multiple_update]
    before_action :remove_unused_state_param, only: [:update]
  end

  private

  def ensure_reviewer
    return if can?(:publish, current_project)

    if (record&.state != 'published' && record_params[:state] == 'published') ||
        params[:state] == 'published'

      redirect_to polymorphic_path([current_project, record]), alert: 'Unable to publish record!'
    end
  end

  def record
    return unless params[:id]

    klass = controller_name.classify.constantize
    klass.find(params[:id])
  end

  def record_params
    self.send("#{controller_name.singularize}_params")
  end

  # If the user is not a reviewer, and the record is currently set as
  # 'Published', the radio button will be disabled and record_params[:state]
  # will be '' (empty string). Since an empty state is invalid, we delete
  # the param here instead.
  def remove_unused_state_param
    return if can?(:publish, current_project)

    if record&.state == 'published' && record_params[:state] == ''
      params[controller_name.singularize].delete(:state)
    end
  end
end
