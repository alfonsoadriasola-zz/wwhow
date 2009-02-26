class PasswordReset < ActiveRecord::Migration
  def self.up
    add_column 'web_users', :password_reset_code,       :string, :limit => 40
    add_column 'web_users', :is_admin,                  :boolean, :default =>false
  end

  def self.down
  end
end
