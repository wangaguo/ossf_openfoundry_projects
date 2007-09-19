require File.dirname(__FILE__) + '/../../test_helper'
require 'relevance/string_additions'

class Relevance::StringAdditionsTest < Test::Unit::TestCase
  def test_const_for_name
    assert_equal String, 'String'.to_const
    assert_equal String, '::String'.to_const
    assert_equal false, 'Flibberty'.to_const
    assert_equal :custom, 'Flibberty'.to_const(:custom)
    assert_equal false, 'String::Flibberty'.to_const
  end
  
  def test_variableize
    assert_equal "this_works", "this::works".variableize
    assert_equal "this_works_too", "this/works/too".variableize
  end
end
