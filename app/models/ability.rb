class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new

    if user.access == 1       ## Administrador
      can :manage, :all
    else
      can :live_search, :all  ## for default read all live_search
      if user.access == 2     ## Operador 
        can :manage, Student
        can :manage, Program
      end
    end
  end
end
