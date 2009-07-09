require 'test_helper'

class BlogEntryTest < ActiveSupport::TestCase
  def test_should_set_attributes_from_text
    b = blog_entries(:two)
    assert "spoon"==b.what
    b.set_attributes_from_text
    assert_equal "what", b.what
    assert_equal "BOGOF",b.display_price    
  end




end
