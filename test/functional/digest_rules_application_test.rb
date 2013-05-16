require File.expand_path('../../test_helper', __FILE__)

class DigestRulesControllerTest < ActionController::TestCase
  fixtures :users, :user_preferences, :roles, :projects, :members, :member_roles,
           :issues, :issue_statuses, :trackers


  def setup
    @controller = DigestRulesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @user = User.find(1) # admin
    User.current = @user
    @request.session[:user_id] = @user.id
    @digest_rule = @user.digest_rules.create!(
        :active => true,
        :project_selector => DigestRule::ALL,
        :recurrent => DigestRule::DAILY
    )
  end

  def test_get_new
    get :new
    assert_response :success
  end

  def test_post_create
    assert_difference 'DigestRule.count', 1 do
      post :create, :digest_rule => {
          :active => true,
          :project_selector => DigestRule::ALL,
          :recurrent => DigestRule::DAILY }
    end

    assert_redirected_to '/my/account'
  end

  def test_get_edit
    get :edit, :id => @digest_rule.id
    assert_response :success
  end

  def test_put_update
    attrs = { :project_selector => DigestRule::MEMBER,
              :recurrent => DigestRule::MONTHLY }
    put :update, :id => @digest_rule.id, :digest_rule => attrs

    assert_redirected_to '/my/account'
    @digest_rule.reload
    assert_equal attrs[:project_selector], @digest_rule.project_selector
    assert_equal attrs[:recurrent], @digest_rule.recurrent
  end

  def test_post_destroy
    post :destroy, :id => @digest_rule.id

    assert_redirected_to '/my/account'
    digest_rule = DigestRule.find_by_id(@digest_rule.id)
    assert_nil digest_rule
  end

  def test_move_higher
    @user.digest_rules.create!(
        :active => true,
        :project_selector => DigestRule::MEMBER,
        :recurrent => DigestRule::MONTHLY
    )
    h1 = DigestRule.by_position[0]
    h2 = DigestRule.by_position[1]

    assert_equal 1, h1.position
    assert_equal 2, h2.position

    put :update, :id => h2.id, :digest_rule => { 'move_to' => 'higher' }

    assert_response :redirect

    h1.reload
    h2.reload

    assert_equal 2, h1.position
    assert_equal 1, h2.position
  end

  def test_move_lower
    @user.digest_rules.create!(
        :active => true,
        :project_selector => DigestRule::MEMBER,
        :recurrent => DigestRule::MONTHLY
    )
    h1 = DigestRule.by_position[0]
    h2 = DigestRule.by_position[1]

    assert_equal 1, h1.position
    assert_equal 2, h2.position

    put :update, :id => h1.id, :digest_rule => { 'move_to' => 'lower' }

    assert_response :redirect

    h1.reload
    h2.reload

    assert_equal 2, h1.position
    assert_equal 1, h2.position
  end
end
