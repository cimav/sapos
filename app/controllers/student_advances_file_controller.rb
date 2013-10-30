class StudentAdvancesFileController < ApplicationController
  def index
    @student = Student.includes(:program).find(params[:id])
    @term_student = TermStudent.joins(:term).where("term_students.student_id=? and terms.start_date<=? and terms.end_date>=?",@student.id,Date.today,Date.today)
    render :layout=>false
  end

  def destroy
    @saf = StudentAdvancesFile.find(params[:id])
    @id  = @saf.term_student.student_id
    @saf.destroy
    flash[:notice] = "Archivo Eliminado."
    redirect_to :action => 'index', :id=>@id
  end

  def upload_file
    file = params[:student_advances_file]['file']
    ts = TermStudent.find(params[:student_advances_file][:term_student_id])
    logger.info "FILEEEEEEEEEEEEEEE: #{file.nil?} #{file.class}"

    if file.nil?
      flash[:error] = "Debes elegir un archivo"
      return redirect_to :action => 'index', :id=> ts.student.id
    end

    file.each do |f|
      @student_advances_file = StudentAdvancesFile.new
      @student_advances_file.term_student_id = params[:student_advances_file]['term_student_id']
      @student_advances_file.student_advance_type = params[:student_advances_file]['student_advance_type']
      @student_advances_file.file = f
      @student_advances_file.description = f.original_filename
      if @student_advances_file.save
        flash[:notice] = "Archivo subido exitosamente."
      else
        flash[:error] = "Error al subir archivo. #{@student_advances_file.errors.full_messages}"
      end
    end
    return redirect_to :action => 'index',:id=> ts.student.id
  end

  def file
    sf = StudentAdvancesFile.find(params[:id]).file
    send_file sf.to_s, :x_sendfile=>true
  end
end
