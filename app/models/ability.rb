class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new
    if user.access == User::MANAGER
      if user.program_type == Program::P_PROPEDEUTICOS
        can :manage, [Student,Program,Internship]
      else
        can :manage, :all
      end
    end 

    if user.access == User::ADMINISTRATOR
        can :manage, [Student ,Staff, Program, Internship, Institution, Classroom, Laboratory, Department, Graduate, Scholarship, CommitteeSession, CommitteeAgreement, Seminar]
        can :manage, User
        cannot [:create,:destroy,:update], User
        cannot [:create,:destroy], Student
    else
      can :live_search, :all  ## for default read all live_search
      if user.access == User::OPERATOR
        can :manage, Internship
        cannot [:create], Internship
      elsif user.access == User::STUDENT
        can :manage, Internship
      elsif user.access == User::OPERATOR_READER
        can :manage, Internship
        cannot [:create], Internship

        can :read, [Student ,Staff, Program, Internship, Institution, Classroom, Laboratory, Department, Graduate, Scholarship,User, CommitteeSession, CommitteeAgreement, Seminar]
      end
    end
  end
end
