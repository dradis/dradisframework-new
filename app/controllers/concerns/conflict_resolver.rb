module ConflictResolver
  protected

  # This concern lets us guard users against the following scenario:
  #
  # 1. User 1 opens a record's 'edit' page
  # 2. User 2 opens the same record's 'edit' page
  # 3. User 1 saves an update
  # 4. User 2 saves their own update, overwriting User 1's recent changes
  #
  # With this method we don't prevent the overwrite from happening, but we
  # detect when it happens and warn the user post-save, so they can check in
  # the record's revision history and fix any problems.
  #
  # To make it work, call check_for_edit_conflicts in #update after a
  # successful update, then call load_conflicting_revisions in whatever
  # controller action the user is redirected to next (typically #show)

  def check_for_edit_conflicts(record, updated_at_before_save)
    name = record.model_name.name.downcase

    return unless params[name][:original_updated_at]

    if params[name][:original_updated_at].to_i < updated_at_before_save
      # Even if there have been edit conflicts, the save will still be
      # successful, which means we're going to *redirect* to another action
      # (#show), rather than just simply rendering a template - which means
      # all the current variables and params will be forgotten. But we still
      # need to pass information about the edit conflicts to the next action,
      # so we use the flash.
      #
      # Only primitive types (String, Array, Hash) can be saved in the flash;
      # we can't use it to pass a Time objec - so pass the time as a string.
      session[:update_conflicts_since] = Time.at(params[name][:original_updated_at].to_i + 1).utc.to_fs(:db)
    end
  end

  def load_conflicting_revisions(record)
    if session[:update_conflicts_since]
      @conflicting_revisions = record.versions\
        .order('created_at ASC')\
        .where('created_at > ?', session[:update_conflicts_since])
      session.delete(:update_conflicts_since)
    end
  end
end
