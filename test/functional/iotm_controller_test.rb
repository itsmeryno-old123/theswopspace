require 'test_helper'

class IotmControllerTest < ActionController::TestCase
  test "should get list" do
    get :list
    assert_response :success
  end

  test "should get previous" do
    get :previous
    assert_response :success
  end

end
