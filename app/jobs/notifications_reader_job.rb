class NotificationsReaderJob < ApplicationJob
  NOTIFIABLE_TYPES = ['Project', 'Dradis::Pro::Plugins::Remediationtracker::Ticket']

  queue_as :dradis_project

  def perform(notifiable_id:, notifiable_type:, user_id:)
    @user_id = user_id

    Notification.transaction do
      @notifiable = notifiable_type.constantize.find_by(id: notifiable_id)

      mark_notifications_from_tasks if NOTIFIABLE_TYPES.include?(notifiable_type)
      mark_notifications_from_comments

      if Notification.unread.where(recipient_id: user_id).count == 0
        NotificationsChannel.broadcast_to(User.find(user_id), 'all_read')
      end
    end
  end

  private

  # Mark all task notifications from the notifiable as read
  def mark_notifications_from_tasks
    @notifiable.notifications.unread.where(recipient_id: @user_id, action: :assign).
      mark_all_as_read!
  end

  # Mark all notifications from the notifiable's comment as read
  def mark_notifications_from_comments
    notifications_from_comments.unread.where(recipient_id: @user_id).mark_all_as_read!
  end

  # Fetch all notifications from all comments in the notifiable
  def notifications_from_comments
    Notification.
      joins('INNER JOIN comments ON notifications.notifiable_id = comments.id').
      where(notifiable_type: 'Comment').
      where(
        'comments.commentable_type = ? AND comments.commentable_id = ?',
        @notifiable.class.to_s,
        @notifiable.id
      )
  end
end
