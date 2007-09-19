# This list_columns setup used by filter_helper_functional_test/test_advanced_filter_columns_with_fields
# to test that the advanced filtering filters on the correct fields.
class ArticleUI < Streamlined::UI
  user_columns :title, 
               :authors, 
                {
                  :show_view => [:name, {:fields => [:first_name, :last_name, :full_name]}],
                  :edit_view => [:select, {:fields => [:first_name, :last_name, :full_name]}]
                }
end

module ArticleAdditions
end

Article.class_eval {include ArticleAdditions}