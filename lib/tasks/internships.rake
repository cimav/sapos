# coding: utf-8
namespace :internships do
  desc "System Administrator Scripts"
  task :duplicate  => :environment do
    internships = Internship.where(:id=>[5228,5243,5231,5242,5124,5117,5110,5112,5125,5119])
    internships.each do |i|
      puts "#{i.id}|#{i.full_name}"
      new_i            = i.dup
      new_i.status     = 0
      new_i.start_date = '2019-09-03'
      new_i.end_date   = '2019-12-13'
      new_i.staff_id   = 50  ## Eduardo Herrera
      new_i.notes      = "Registro duplicado por script"
      if new_i.save(:validate=>false)
        puts "OK"
      else
        puts new_i.errors.full_messages
      end
    end ## each
  end ## task duplicate
end ## namespace
