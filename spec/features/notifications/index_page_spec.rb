require 'rails_helper'

describe 'notifications index page' do
  before do
    login_to_project_as_user
  end

  let(:me) { @logged_in_as }
  let(:u1) { create(:user) }
  let(:u2) { create(:user) }

  def create_notification(opts = {})
    opts[:notifiable] ||= create(:comment)
    create(:notification, opts)
  end

  example 'when I have no notifications' do
    # other users have notifications but you don't:
    create_notification(recipient: u1)
    create_notification(recipient: u2)

    visit project_notifications_path(@project)

    expect(page).not_to have_selector '.notification'
    expect(page).to have_content "You don't have any notifications yet"
  end

  example 'when I have notifications' do
    # my notifications: 1 read, 1 unread
    create_notification(recipient: me)
    create_notification(recipient: me, read_at: Time.now)

    # other people's notifications:
    create_notification(recipient: u1)
    create_notification(recipient: u2)

    visit project_notifications_path(@project)
    expect(page).to have_selector('.notification', count: 2, wait: 10)
    expect(page).not_to have_content "You don't have any notifications yet."
  end

  example 'marking all notifications as read', :js do
    unread_notif_1 = create_notification(recipient: me)
    unread_notif_2 = create_notification(recipient: me)
    read_notif     = create_notification(recipient: me, read_at: Time.now)

    not_mine = [
      create_notification(recipient: u1),
      create_notification(recipient: u2),
    ]

    visit project_notifications_path(@project)

    expect do
      click_link 'Mark all as read'
    end.not_to change { read_notif.reload.read_at }

    expect(page).to have_no_css('.notification.unread')

    expect(unread_notif_1.reload.read_at).to be_within(10.seconds).of(Time.now)
    expect(unread_notif_2.reload.read_at).to be_within(10.seconds).of(Time.now)

    not_mine.each { |notif| expect(notif.reload.read_at).to be_nil }
  end

  example 'marking a notification as read', :js do
    notif = create_notification(recipient: me)

    visit project_notifications_path(@project)

    expect(page).to have_css('.notification.unread')
    find('.notification-read').click
    expect(page).to have_no_css('.notification.unread')

    expect(notif.reload.read_at).to be_within(5.seconds).of(Time.now)
  end
end
