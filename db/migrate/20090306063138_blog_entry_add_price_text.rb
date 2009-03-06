class BlogEntryAddPriceText < ActiveRecord::Migration
  def self.up
     add_column "blog_entries", :price_text, :string
  end

  def self.down
  end
end
