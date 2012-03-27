class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new

    if user.access == User::ADMINISTRATOR
      can :manage, :all
    else
      can :live_search, :all  ## for default read all live_search
      if user.access == User::OPERATOR
        can :manage, Student
        can :manage, Program
      end
    end
  end
end
