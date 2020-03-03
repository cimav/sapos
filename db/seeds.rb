# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)


# Countries
puts "Populating Countries..."
Country.destroy_all
ActiveRecord::Base.connection.execute('ALTER TABLE countries AUTO_INCREMENT = 1')
open("db/seeds/countries.txt") do |countries|
    countries.read.each_line do |country|
        code, name = country.chomp.split("|")
        Country.create!(:name => name, :code => code)
    end
end

# Populate Mexico States
puts "Populating States..."
State.destroy_all
ActiveRecord::Base.connection.execute('ALTER TABLE states AUTO_INCREMENT = 1')
open("db/seeds/states.txt") do |states|
    states.read.each_line do |state|
        code, name, federal_entity = state.chomp.split("|")
        State.create!(:name => name, :code => code, :federal_entity => federal_entity)
    end
end

