# coding: utf-8
class TermCourseSchedule < ActiveRecord::Base
  attr_accessible :id,:term_course_id,:day,:start_hour,:end_hour,:classroom_id,:staff_id,:start_date,:end_date,:class_type,:status,:created_at,:updated_at
  belongs_to :term_course
  belongs_to :staff
  belongs_to :classroom

  validate :splice_schedules_search_engine
  validates :staff_id, :presence => true

  ACTIVE   = 1
  INACTIVE = 2

  MONDAY    = 1
  TUESDAY   = 2
  WEDNESDAY = 3
  THURSDAY  = 4
  FRIDAY    = 5
  SATURDAY  = 6
  SUNDAY    = 7

  DAY = {MONDAY    => 'Lunes',
         TUESDAY   => 'Martes',
         WEDNESDAY => 'Miercoles',
         THURSDAY  => 'Jueves',
         FRIDAY    => 'Viernes',
         SATURDAY  => 'Sabado',
         SUNDAY    => 'Domingo'}

  PRESENTIAL = 1
  VIRTUAL    = 2
 
  CLASSTYPE = {PRESENTIAL => 'Presencial',
               VIRTUAL    => 'Virtual'}

  HOURS = [['06:00', '06:00'],
           ['07:00', '07:00'],
           ['08:00', '08:00'],
           ['09:00', '09:00'],
           ['10:00', '10:00'],
           ['11:00', '11:00'],
           ['12:00', '12:00'],
           ['13:00', '13:00'],
           ['14:00', '14:00'],
           ['15:00', '15:00'],
           ['16:00', '16:00'],
           ['17:00', '17:00'],
           ['18:00', '18:00'],
           ['19:00', '19:00'],
           ['20:00', '20:00'],
           ['21:00', '21:00'],
           ['22:00', '22:00']]

  def day_name
    DAY[day]
  end

  def class_type_name
    CLASSTYPE[class_type]
  end

  def splice_schedules_search_engine
    if self.start_date > self.end_date
      errors.add(:start_date, "La fecha final no puede ser menor que la inicial")
    end

    if self.start_hour >= self.end_hour
      errors.add(:start_date, "La hora final no debe ser menor o igual a la final")
    end
    
    tcs = TermCourseSchedule.where(:classroom_id=>self.classroom_id,:day=>self.day).where("(:start_date between start_date AND end_date) OR (:end_date between start_date AND end_date) OR (start_date >= :start_date AND end_date <= :end_date)",{:start_date=>self.start_date,:end_date=>self.end_date})
    tcs = tcs.where("(:start_hour between start_hour AND end_hour) OR (:end_hour between start_hour AND end_hour) OR (start_hour >= :start_hour AND end_hour <= :end_hour)",{:start_hour=>(self.start_hour+1*60).strftime('%H:%M:%S'),:end_hour=>(self.end_hour-1*60).strftime('%H:%M:%S'),:own_id=>self.term_course_id})
    tcs = tcs.where("id != ?",self.id.to_i)
    
    ndays = (self.start_date..self.end_date).to_a.select {|k| [self.day].include?(k.wday)}

    if tcs.size > 0
      tcs.each do |t|
        days = (t.start_date..t.end_date).to_a.select {|k| [t.day].include?(k.wday)}
        days.each do |d|
          if ndays.include?(d)
            errors.add(:start_date, "Se empalman horarios para esta Aula con #{t.term_course.course.name}")
            break
          end
        end
      end

      
    end
  end
end
