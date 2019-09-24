# coding: utf-8
namespace :internships do
  desc "System Administrator Scripts"
  task :duplicate  => :environment do
    array = [5113]
    internships = Internship.where(:id=>array)
    internships.each do |i|
      puts "#{i.id}|#{i.full_name}"
      new_i            = i.dup
      new_i.status     = 0
      new_i.start_date = '2019-09-03'
      new_i.end_date   = '2019-12-13'
      new_i.staff_id   =  68   ## 50 Eduardo Herrera
      new_i.notes      = "Registro duplicado por script"
      if new_i.save(:validate=>false)
        puts "OK"
      else
        puts new_i.errors.full_messages
      end
    end ## each
  end ## task duplicate
end ## namespace
