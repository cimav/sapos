# coding: utf-8
class ReportsController < ApplicationController
  before_filter :auth_required
  respond_to :html, :xml, :json

  def index
    @staffs = Staff.where("status != #{Staff::INACTIVE}")
  end

  def get_evaluation_term_courses
    staff = Staff.find(params[:staff_id])
    term_courses = staff.teacher_evaluations.map{|te| {term_course_id:te.term_course_id, term_course_name:"#{te.term_course.course.name} (#{te.term_course.term.code})"}}

    render json:term_courses
  end


end
