class BlogEntryT < ActiveRecord::Migration
  def self.up
     add_column "blog_entries" , "twit_id" , :integer
    
  end

  def self.down
  end
end
