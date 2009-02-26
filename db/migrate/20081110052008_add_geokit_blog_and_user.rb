class AddGeokitBlogAndUser < ActiveRecord::Migration
  def self.up
    add_column "users" , "lat", "float"
    add_column "users",  "lng", "float"
    add_column "blog_entries",  "lat", "float"
    add_column "blog_entries",  "lng", "float"
  end

  def self.down
  end
end
