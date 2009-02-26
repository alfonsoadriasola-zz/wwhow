class AddIndex < ActiveRecord::Migration
  def self.up
    add_index "web_users", ["id"],:unique => true
    add_index "users", ["id"],:unique => true
    add_index "blog_entries", ["id"], :unique => true ,:order => 'desc'
    add_index "blog_entries", ["user_id"]    
    add_index "blog_entries", ["twit_id"], :unique => true
    
  end

  def self.down
  end
end
