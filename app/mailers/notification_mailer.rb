class NotificationMailer < ApplicationMailer
  helper :avatar

  before_action :set_inline_attachments

  def digest
    @notifications = params[:notifications]
    @user = params[:user]
    set_paths_for_user
    @type = params[:type]

    mail to: @user.email, subject: 'You have unread notifications.'
  end

  private

  def set_inline_attachments
    attachments.inline['dradis_logo.png'] =
      File.read(
        Rails.root.join('app', 'assets', 'images', 'logo_full_small.png')
      )
  end

  def set_paths_for_user
    @login_path_for_user = login_url
    @user_preferences_path = edit_user_preferences_notifications_url
  end
end
