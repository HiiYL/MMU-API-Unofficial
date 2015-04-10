require 'test_helper'

class ApiControllerTest < ActionController::TestCase
  test "should get timetable" do
    get :timetable
    assert_response :success
  end

end
