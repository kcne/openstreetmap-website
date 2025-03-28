require "test_helper"

class UserTermsSeenTest < ActionDispatch::IntegrationTest
  def test_api_blocked
    user = create(:user, :terms_seen => false, :terms_agreed => nil)

    get "/api/#{Settings.api_version}/user/preferences", :headers => bearer_authorization_header(user)
    assert_response :forbidden

    # touch it so that the user has seen the terms
    user.terms_seen = true
    user.save

    get "/api/#{Settings.api_version}/user/preferences", :headers => bearer_authorization_header(user)
    assert_response :success
  end

  def test_terms_presented_at_login
    user = create(:user, :terms_seen => false, :terms_agreed => nil)

    # try to log in
    get "/login"
    follow_redirect!
    assert_response :success
    assert_template "sessions/new"
    post "/login", :params => { :username => user.email, :password => "test", :referer => "/diary/new" }
    # but now we need to look at the terms
    assert_redirected_to account_terms_path(:referer => "/diary/new")
    follow_redirect!
    assert_response :success

    # don't agree to the terms, but hit decline
    put "/account/terms", :params => { :decline => true, :referer => "/diary/new" }
    assert_redirected_to "/diary/new"
    follow_redirect!

    # should be carried through to a normal login with a message
    assert_response :success
    assert_not flash[:notice].nil?
  end

  def test_terms_cant_be_circumvented
    user = create(:user, :terms_seen => false, :terms_agreed => nil)

    # try to log in
    get "/login"
    follow_redirect!
    assert_response :success
    assert_template "sessions/new"
    post "/login", :params => { :username => user.email, :password => "test", :referer => "/diary/new" }
    # but now we need to look at the terms
    assert_redirected_to account_terms_path(:referer => "/diary/new")

    # check that if we go somewhere else now, it redirects
    # back to the terms page.
    get "/traces/mine"
    assert_redirected_to account_terms_path(:referer => "/traces/mine")
    get "/traces/mine", :params => { :referer => "/diary/new" }
    assert_redirected_to account_terms_path(:referer => "/diary/new")
  end
end
