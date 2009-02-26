class BlogEntry < ActiveRecord::Migration
  def self.up
    add_column "blog_entries" , "what", :string
    add_column "blog_entries" , "where", :string
    add_column "blog_entries" , "price", :float
    add_column "blog_entries" , "original", :float
  end

  def self.down
  end
end
