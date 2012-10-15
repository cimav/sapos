class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new
    if user.access == User::MANAGER
      if user.program_type == Program::P_PROPEDEUTICOS
        can :live_search, :all
        can :manage, Student
        can :manage, Program
        can :manage, Internship
      else
        can :manage, :all
      end
    end 

    if user.access == User::ADMINISTRATOR
        can :live_search, :all
        can [:read, :update, :files, :upload_file, :delete_file, :upload_image, :change_image, :file], Student
        can [:read, :update], User
        can :manage, [Staff, Program, Internship, Institution, Classroom, Laboratory, Department]
    else
      can :live_search, :all  ## for default read all live_search
      if user.access == User::OPERATOR
        can [:read, :update], Student
        can :manage, Internship
      end
    end
  end
end
