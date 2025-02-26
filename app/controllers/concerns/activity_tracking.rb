module ActivityTracking
  protected

  def track_activity(trackable, action, user = current_user, project = nil)
    ActivityTrackingJob.perform_later(
      action: action.to_s,
      project_id: project ? project.id : nil,
      trackable_id: trackable.id,
      trackable_type: trackable.class.to_s,
      user_id: user.id
    )
  end

  def track_assigned(trackable, user: current_user, project: current_project)
    track_activity(trackable, :assign, user, project)
  end

  def track_created(trackable, user: current_user, project: current_project)
    track_activity(trackable, :create, user, project)
  end

  def track_destroyed(trackable, user: current_user, project: current_project)
    track_activity(trackable, :destroy, user, project)
  end

  def track_recovered(trackable, user: current_user, project: current_project)
    track_activity(trackable, :recover, user, project)
  end

  def track_updated(trackable, user: current_user, project: current_project)
    track_activity(trackable, :update, user, project)

    if trackable.respond_to?(:state) && trackable.state_previously_changed?
      track_state_change(trackable)
    end
  end

  def track_state_change(trackable, user: current_user, project: current_project)
    track_activity(trackable, :state_change, user, project)
  end
end
