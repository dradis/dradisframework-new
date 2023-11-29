module Notifiable
  extend ActiveSupport::Concern

  included do
    has_many :notifications, as: :notifiable, dependent: :destroy
  end

  def create_notifications(action:, actor:, recipients:)
    ActiveRecord::Base.transaction do
      recipients.each do |recipient|
        if Ability.new(recipient).can?(:read, self)
          Notification.create(
            action: action,
            actor: actor,
            notifiable: self,
            recipient: recipient
          )
        end
      end
    end
  end
end
