class AddCurrentRank < ActiveRecord::Migration
  def self.up
    add_column "users","rated", :float
    add_column "users","ranked",:string
  end

  def self.down
  end
end
