# coding: utf-8
class ClassroomsController < ApplicationController
  load_and_authorize_resource
  before_filter :auth_required
  respond_to :html, :xml, :json

  def index
  end

  def live_search
    @classrooms = Classroom.order('code')
    if !params[:q].blank?
      @classrooms = @classrooms.where("(name LIKE :n OR code LIKE :n)", {:n => "%#{params[:q]}%"}) 
    end

    render :layout => false
  end

  def show
    @classroom = Classroom.find(params[:id])
    render :layout => false
  end

  def new
    @classroom = Classroom.new
    render :layout => false
  end

  def create
    @classroom = Classroom.new(params[:classroom])

    if @classroom.save
      flash[:notice] = "Aula creada."
      ActivityLog.new({:user_id=>current_user.id,:activity=>"Create Classroom: #{@classroom.id},#{@classroom.name}"}).save

      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:uniq] = @classroom.code
            render :json => json
          else 
            redirect_to @classroom
          end
        end
      end
    else
      flash[:error] = "Error al crear aula."
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:errors] = @classroom.errors
            render :json => json, :status => :unprocessable_entity
          else
            redirect_to @classroom
          end
        end
      end
    end
  end

  def update 
    @classroom = Classroom.find(params[:id])

    if @classroom.update_attributes(params[:classroom])
      flash[:notice] = "Aula actualizada."
      ActivityLog.new({:user_id=>current_user.id,:activity=>"Update Classroom: #{@classroom.id},#{@classroom.name}"}).save
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            render :json => json
          else 
            redirect_to @classroom
          end
        end
      end
    else
      flash[:error] = "Error al actualizar aula."
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:errors] = @classroom.errors
            render :json => json, :status => :unprocessable_entity
          else 
            redirect_to @classroom
          end
        end
      end
    end
  end

  def schedule_table
			@is_pdf				= false 
			@id 					= params[:id]

			@start_date 	= params[:start_date]
			@end_date 		= params[:end_date]
      
      if @start_date.blank? or @end_date.blank?
        @error = 1 # No se pueden mandar fechas vacias
        render :layout => false and return
      end 

      @sd           = Date.parse(@start_date)
      @ed           = Date.parse(@end_date)

      @diference    = @ed - @sd

      if @diference.to_i < 0
        @error  = 2 #La fecha inicial es mayor que la final
        render :layout => false and return
      end
          
			@tcs					= TermCourseSchedule.where("classroom_id = :classroom_id AND ((start_date <= :start_date AND :start_date <= end_date) OR (start_date <= :end_date AND :end_date <= end_date) OR (start_date > :start_date AND :end_date > end_date))",{:classroom_id => params[:id],:start_date => @start_date,:end_date => @end_date});

			@schedule = Hash.new
    	(4..22).each do |i|
      	@schedule[i] = Array.new
      	(1..7).each do |j|
        	@schedule[i][j] = Array.new
      	end
    	end
			n = 0
    	courses = Hash.new
      @min_hour = 24
    	@max_hour = 1
			
				@tcs.each do |session_item| 
						hstart	= session_item.start_hour.hour
						hend   	= session_item.end_hour.hour - 1
					
        		(hstart..hend).each do |h|
						if courses[session_item.term_course.course.id].nil?
							n += 1
							courses[session_item.term_course.course.id] = n
						end

						comments = ""
						if session_item.start_date != session_item.term_course.term.start_date
             	comments += "Inicia: #{l session_item.start_date, :format => :long}\n"
						end
           if session_item.end_date != session_item.term_course.term.end_date
             comments += "Finaliza: #{l session_item.end_date, :format => :long}"
           end
					
	          staff_name = session_item.staff.full_name rescue 'Sin docente'
	
						details = {
							"name" 				=> session_item.term_course.course.name,
							"staff_name" 	=> staff_name,
							"comments"		=> comments,
							"id"					=> session_item.id,
							"n"						=> courses[session_item.term_course.course.id]
						}

  	    		@schedule[h][session_item.day] << details
       			@min_hour = h if h < @min_hour
          	@max_hour = h if h > @max_hour
					end
				end
		
			respond_with do |format|
      	format.html do
        	render :layout => false
      	end
      	format.pdf do
       	 	institution = Institution.find(1)
        	@logo = institution.image_url(:medium).to_s
        	@is_pdf = true
        	html = render_to_string(:layout => false , :action => "schedule_table.html.haml")
        	kit = PDFKit.new(html, :page_size => 'Letter')
        	kit.stylesheets << "#{Rails.root}/public/stylesheets/compiled/pdf.css"
        	filename = "horario-#{@tcs[0].classroom.id}-#{@tcs[0].term_course.term.id}.pdf"
        	send_data(kit.to_pdf, :filename => filename, :type => 'application/pdf')
        	return # to avoid double render call
				end   
      end
		end 
end
