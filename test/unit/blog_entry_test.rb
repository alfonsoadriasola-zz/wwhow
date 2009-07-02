require 'test_helper'

class BlogEntryTest < ActiveSupport::TestCase
  def test_should_set_attributes
    b = blog_entries(:two)
    assert "spoon"==b.what
    b.set_attributes_from_text
    assert "what"==b.what
  end
end
