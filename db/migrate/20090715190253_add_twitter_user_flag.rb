class AddTwitterUserFlag < ActiveRecord::Migration
  def self.up
     add_column "users", :twitter_user, :boolean
  end

  def self.down
  end
end
