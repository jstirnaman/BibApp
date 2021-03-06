# Rake tasks to preform batch operations on works in BibApp
#
require 'rubygems'
require 'rake'

namespace :works_helper do

  desc "Deletes a batch of works for a person. Ex: 'rake works_helper:batch_delete person_id=7'."
  task :batch_destroy => :environment do
    if ENV['person_id']
      @works = Person.find("#{ENV['person_id']}").works
      @works.each do |work|
        work.destroy
      end
    else
      puts "Usage example: 'rake works_helper:batch_delete person_id=7'"
    end
  end

  desc "Deletes all works"
  task :batch_destroy_all => :environment do
    @works = Work.all
    @works.each do |work|
      work.destroy
    end
  end
  
  desc "Deletes a batch of works given a file of Work IDs, one per line. Ex: rake works_helper:batch_destroy_list works='dupes_list.txt'"
  task :batch_destroy_list => :environment do
    if ENV['works']
      @works = IO.readlines(ENV['works'])
      puts "Attempting to delete #{@works.length} works...."
      @works.each {|w| w.strip!}
      @works.each do |w| 
        begin
          Work.find(w).destroy
        rescue Exception # Don't bail if the work isn't found.
          STDERR.puts "Could not delete Work #{w}. Maybe it's already been deleted?"
        end
      end
    else
      puts "Usage example: 'rake works_helper:batch_destroy_list works='dupes_list.txt'"
    end
  end
  
  desc "Merges each work in a list of works with the work's duplicate candidates.
       Requires a +works+ file of Work IDs, one per line.
       Takes an optional +rows+ variable specifying how many duplicate candidates will be returned by
       Solr. Default is 3.
       Takes an optional +status+ variable for specifying which sets of duplicate
       candidates should be merged. Possible values are 'UNACCEPTED', 'ACCEPTED', or 'ALL' (default)
       Ex: rake works_helper:batch_merge_duplicates_list works='dupes_list.txt' status='ALL'"
  task :batch_merge_duplicates_list => :environment do
    if ENV['works'] && @works = IO.readlines(ENV['works'])
      puts "Attempting to merge #{@works.length} works with their duplicate candidates...."
      @works.each {|w| w.strip!}
      @works.each do |w|
        @status = ENV['status'] || 'ALL'
        @rows = ENV['rows'] || 3
        @status.strip!     
        begin
          Work.find(w).merge_duplicates(@status, @rows)
        rescue Exception # Don't bail if the work isn't found.
          STDERR.puts "Could not merge Work #{w}. Maybe it's already been deleted?"
        end
      end
    else
      puts "Missing works file. Usage example: Ex: bundle exec rake works_helper:batch_merge_duplicates_list works='dupes_list.txt' work_status='ALL'"
    end
  end
  
  desc "Merges all duplicates (accepted and unaccepted!) in orphaned works."
  task :batch_merge_duplicate_orphans => :environment do
    count_start = Work.orphans.size
    puts count_start.to_s + " orphaned works. This could take a while."
    orphans_with_error = []
    Work.orphans.each do |w|
      begin
        w.merge_duplicates # Merges accepted and unaccepted duplicates!
      rescue Exception => e
        orphans_with_error << w.id
        STDERR.puts "Could not merge Work #{w}. #{e}"
        STDERR.puts "work_id added to error list."
      end
    end
    count_end = Work.orphans.size
    puts "Finished merging orphans. Merged #{count_start - count_end} works."
    puts "You now have #{count_end} orphaned works."
    puts "Encountered errors while attempting to merge these works:"
    puts orphans_with_error.join(', ')
  end

end