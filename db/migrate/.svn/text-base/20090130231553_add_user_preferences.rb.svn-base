class AddUserPreferences < ActiveRecord::Migration
  def self.up
    add_column "users", :show_friends_only, :boolean,  :default => false, :null => false
    add_column "users", :hide_blocked_users, :boolean, :default => true, :null => false
  end

  def self.down
  end
end
