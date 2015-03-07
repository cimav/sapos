# coding: utf-8
require 'csv'
namespace :departments do
  desc "Assign staffs to departments"
  ##################################################################################################################################
  #####                                           TASK STAFFS                                                                  #####
  ##################################################################################################################################
  task :check => :environment do
    @areas = [["SERVICIOS GENERALES", 9],
              ["CONTABILIDAD", 9],
              ["INGENIERIA Y QUIMICA DE MATERIALES", 11],
              ["ESTUDIOS DE POSGRADO", 3],
              ["METALURGIA E INTEGRIDAD ESTRUCTURAL", 13],
              ["MEDIO AMBIENTE Y ENERGIA", 12],
              ["DIRECCION DE VINCULACION", 8],
              ["DIRECCION ACADEMICA", 2],
              ["FISICA DE MATERIALES", 10 ],
              ["PRESUPUESTO", 9],
              ["DIRECCION DE ADMON Y FINANZAS", 9],
              ["ADQUISICIONES", 9],
              ["NANOTECNOLOGIA", 6],
              ["TELECOMUNICACIONES Y SISTEMAS", 5],
              ["RECURSOS HUMANOS", 9],
              ["DIRECCION DE PLANEACION Y ASUNTOS E",7],
              ["DIRECCION GENERAL",1]]

    @file        = "#{Rails.root}/private/Listado.csv"
    @employees   = []
    @counter     = 0
    @counter_yes = 0
    puts @file
    File.open(@file,'r') do |f|
      CSV.foreach(f, col_sep:",") do |l|
        @areas.each do |a|
          if a[0].eql? l[5]
            s = Staff.where(:employee_number=>l[0])
            @employees << "#{l[0]} #{l[1]} #{l[2]} #{s.size>0 ? '[YES]':'-NO-'}"
            if s.size>0
              s[0].area_id = 5
              if s[0].save
               puts "Todo ok"
               @counter_yes = @counter_yes + 1
              else
                puts "Algo fallo: #{s[0].errors.full_messages}"
              end
            end
            @counter = @counter + 1
          end#if
        end#@areas
      end#CSV
    end#File.open
    @employees.each { |a| print a, "\n" }
    @percentage = (@counter_yes*100)/@counter.to_f
    puts "Hay #{@counter_yes} registros encontrados de #{@counter} o sea el #{@percentage}%\n"
  end#task :staffs
  ##################################################################################################################################
  #####                                           TASK INTERNSHIPS                                                             #####
  ##################################################################################################################################
  task :internships => :environment do
    @areas = [["a Ambiental", 12],
    ["Posgrado",3],
    ["Laboratorios y Talleres",4],
    ["as de la Informaci",5],
    ["DIQM",11],
    ["n Acad",2],
    ["ERPMA",12],
    ["sica de Matriales",10],
    ["mica de Materiales",11],
    ["mica de p",11],
    ["Medio Ambiente y Energ",12],
    ["Integridad Estructural",13],
    ["NANOTECH",6],
    ["n y Seguimiento",7],
    ["Polimeros",11],
    ["Taller de Prototipos",4],
    ["Laboratorio",4]]

    @internships = Internship.where("created_at>'2015-01-20'")
    @flag    = false
    @area_id = 0
    @counter     = 0
    @counter_yes = 0

    @internships.each do |i|
      @areas.each do |a|
        if !i.office.nil?
          if i.office.include? a[0]
            @area_id = a[1]
            @flag    = true
          end#if i.office
        end#if !i.office
      end#@areas
      print "#{i.id} #{i.first_name} #{i.last_name} #{i.office} #{@flag==true ? '[YES]':'-NO-'}\n"
      if @flag
        i.area_id= @area_id
        if i.save
          puts "Todo ok"
          @counter_yes = @counter_yes + 1
        else
          puts "Algo fallo: #{i.errors.full_messages}"
        end
      end#@flag
      @flag    = false
      @area_id = 0
      @counter = @counter + 1
    end#@internships

    @percentage = (@counter_yes*100)/@counter.to_f
    print "Hubo #{@counter} registros y se cambiaron #{@counter_yes} es decir el #{@percentage}%\n"

  end#task :internships
  ##################################################################################################################################
  #####                                           TASK  GET                                                                    #####
  #####                        Para obtener las areas disponibles en archivo                                                   #####
  ##################################################################################################################################
  task :get => :environment do
    @names   = []
    @file    = "#{Rails.root}/private/Listado.csv"
    @counter = 0
    File.open(@file,'r') do |f|
      CSV.foreach(f, col_sep:",") do |l|
        if @names.size.eql? 0
          @names << [l[5],1]
        else
          @names.each do |n|
            if n[0].eql? l[5]
              n[1] = n[1] + 1
            else
              @names << [l[5],1]
            end
          end
        end
      end#CSV
    end#File.open
    print @names
  end#task :get
end#namespace
