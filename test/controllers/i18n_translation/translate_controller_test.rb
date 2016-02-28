require 'test_helper'

module I18nTranslation
  class TranslateControllerTest < ActionController::TestCase
    setup do
      @routes = Engine.routes
    end

    test "should get index" do
      get :index
      assert_response :success
    end

    test "should get translate" do
      get :translate
      assert_response :success
    end

  end
end
