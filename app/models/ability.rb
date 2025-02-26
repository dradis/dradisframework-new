class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)

    can [:read, :use, :update], Project, authors: { id: [user.id] }
    can [:publish], Project, reviewers: { id: [user.id] }
    can [:create, :read], Comment
    can [:update, :destroy], Comment, user_id: user.id
    can :manage, Tag
  end
end
