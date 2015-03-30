class AddOrcidToPerson < ActiveRecord::Migration
  def self.up
    add_column :people, :orcid, :string
  end

  def self.down
    remove_column :people, :orcid, :string
  end
end
