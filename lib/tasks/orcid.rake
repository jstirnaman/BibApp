# Rake tasks to preform batch operations on works in BibApp
#
require 'rubygems'
require 'rake'
require 'orcid_client'

namespace :orcid do
  File_Path = "/public/orcid/"
  desc "Writes ORCID person to file if file is absent and if record has changed. Ex: 'rake orcid:fetch person_id=7'."
  task :fetch, [:person_id] => :environment do |t, args|
    if ENV['person_id']
      person_id = ENV['person_id']
    else
      person_id = args.person_id
    end
    if person_id
      person_orcid = "#{person_id}.orcid"
      file = Rails.root.to_s + File_Path + "#{person_orcid}"
      person = Person.find(person_id)
      begin
        validate_with_schema(file)
      rescue Exception => e
        create_file(file, person_orcid)
      end

      if File.size?(file).nil? || File.atime(file) < person.updated_at || File.atime(file) < person.contributorships.sort_by{|c| c.updated_at}.last.updated_at
        begin
          create_file(file, person_orcid)
          validate_with_schema(file)
        rescue Exception => e
          raise e
        end
      end
    else
      puts "Usage example: 'rake orcid:fetch person_id=7'"
    end
  end

  desc "Writes ORCiD output for first n (default = 100) people to files."
  task :fetch_n => :environment do
    n = ENV['n'].to_i || 100
    STDOUT.puts "Fetching #{n} profiles..."
    Person.select(:id).where(active: true).first(n).each do |p|
      begin
        Rake::Task["orcid:fetch"].invoke(p.id)
        Rake::Task["orcid:fetch"].reenable
      rescue Exception => e
        raise e
      end
    end
  end

  desc "Validates BibApp ORCiD for a person against the ORCiD schema specified in lib/orcid_client.rb"
  task :validate => :environment do
    if ENV['person_id']
      person_id = ENV['person_id']
      person_orcid = "#{person_id}.orcid"
      file = Rails.root.to_s + File_Path + "#{person_orcid}"
      validate_with_schema(file)
    else
      puts "Usage example: 'rake orcid:validate person_id=7'"
    end
  end
end

def create_file(file, person_orcid)
  File.open(file, "w") do |f|
    STDOUT.puts "Fetching #{person_orcid}"
    f << HTTParty.get($APPLICATION_URL + '/people/' + person_orcid).body
  end
rescue Exception => e
  raise e
end

def validate_with_schema(file)
  oc = Orcid::OrcidApi.new
  v = oc.validate(file, oc.orcid_version).inspect
  raise v unless v.empty?
rescue Exception => e
  raise e
end
