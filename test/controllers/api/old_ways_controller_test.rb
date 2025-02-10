require "test_helper"

module Api
  class OldWaysControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/api/0.6/way/1/history", :method => :get },
        { :controller => "api/old_ways", :action => "index", :way_id => "1" }
      )
      assert_routing(
        { :path => "/api/0.6/way/1/history.json", :method => :get },
        { :controller => "api/old_ways", :action => "index", :way_id => "1", :format => "json" }
      )
      assert_routing(
        { :path => "/api/0.6/way/1/2", :method => :get },
        { :controller => "api/old_ways", :action => "show", :way_id => "1", :version => "2" }
      )
      assert_routing(
        { :path => "/api/0.6/way/1/2.json", :method => :get },
        { :controller => "api/old_ways", :action => "show", :way_id => "1", :version => "2", :format => "json" }
      )
      assert_routing(
        { :path => "/api/0.6/way/1/2/redact", :method => :post },
        { :controller => "api/old_ways", :action => "redact", :way_id => "1", :version => "2" }
      )
    end

    ##
    # check that a visible way is returned properly
    def test_index
      way = create(:way, :with_history, :version => 2)

      get api_way_versions_path(way)

      assert_response :success
      assert_dom "osm:root", 1 do
        assert_dom "> way", 2 do |dom_ways|
          assert_dom dom_ways[0], "> @id", way.id.to_s
          assert_dom dom_ways[0], "> @version", "1"

          assert_dom dom_ways[1], "> @id", way.id.to_s
          assert_dom dom_ways[1], "> @version", "2"
        end
      end
    end

    ##
    # check that an invisible way's history is returned properly
    def test_index_invisible
      get api_way_versions_path(create(:way, :with_history, :deleted))
      assert_response :success
    end

    ##
    # check chat a non-existent way is not returned
    def test_index_invalid
      get api_way_versions_path(0)
      assert_response :not_found
    end

    ##
    # test that redacted ways aren't visible in the history
    def test_index_redacted_unauthorised
      way = create(:way, :with_history, :version => 2)
      way.old_ways.find_by(:version => 1).redact!(create(:redaction))

      get api_way_versions_path(way)

      assert_response :success, "Redaction shouldn't have stopped history working."
      assert_dom "osm way[id='#{way.id}'][version='1']", 0,
                 "redacted way #{way.id} version 1 shouldn't be present in the history."

      get api_way_versions_path(way, :show_redactions => "true")

      assert_response :success, "Redaction shouldn't have stopped history working."
      assert_dom "osm way[id='#{way.id}'][version='1']", 0,
                 "redacted way #{way.id} version 1 shouldn't be present in the history when passing flag."
    end

    def test_index_redacted_normal_user
      way = create(:way, :with_history, :version => 2)
      way.old_ways.find_by(:version => 1).redact!(create(:redaction))

      get api_way_versions_path(way), :headers => bearer_authorization_header

      assert_response :success, "Redaction shouldn't have stopped history working."
      assert_dom "osm way[id='#{way.id}'][version='1']", 0,
                 "redacted node #{way.id} version 1 shouldn't be present in the history, even when logged in."

      get api_way_versions_path(way, :show_redactions => "true"), :headers => bearer_authorization_header

      assert_response :success, "Redaction shouldn't have stopped history working."
      assert_dom "osm way[id='#{way.id}'][version='1']", 0,
                 "redacted node #{way.id} version 1 shouldn't be present in the history, even when logged in and passing flag."
    end

    def test_index_redacted_moderator
      way = create(:way, :with_history, :version => 2)
      way.old_ways.find_by(:version => 1).redact!(create(:redaction))
      auth_header = bearer_authorization_header create(:moderator_user)

      get api_way_versions_path(way), :headers => auth_header

      assert_response :success, "Redaction shouldn't have stopped history working."
      assert_dom "osm way[id='#{way.id}'][version='1']", 0,
                 "way #{way.id} version 1 should not be present in the history for moderators when not passing flag."

      get api_way_versions_path(way, :show_redactions => "true"), :headers => auth_header

      assert_response :success, "Redaction shouldn't have stopped history working."
      assert_dom "osm way[id='#{way.id}'][version='1']", 1,
                 "way #{way.id} version 1 should still be present in the history for moderators when passing flag."
    end

    def test_show
      way = create(:way, :with_history, :version => 2)

      get api_way_version_path(way, 1)

      assert_response :success
      assert_dom "osm:root", 1 do
        assert_dom "> way", 1 do
          assert_dom "> @id", way.id.to_s
          assert_dom "> @version", "1"
        end
      end

      get api_way_version_path(way, 2)

      assert_response :success
      assert_dom "osm:root", 1 do
        assert_dom "> way", 1 do
          assert_dom "> @id", way.id.to_s
          assert_dom "> @version", "2"
        end
      end
    end

    ##
    # test that redacted ways aren't visible, regardless of
    # authorisation except as moderator...
    def test_show_redacted_unauthorised
      way = create(:way, :with_history, :version => 2)
      way.old_ways.find_by(:version => 1).redact!(create(:redaction))

      get api_way_version_path(way, 1)

      assert_response :forbidden, "Redacted way shouldn't be visible via the version API."

      get api_way_version_path(way, 1, :show_redactions => "true")

      assert_response :forbidden, "Redacted way shouldn't be visible via the version API when passing flag."
    end

    def test_show_redacted_normal_user
      way = create(:way, :with_history, :version => 2)
      way.old_ways.find_by(:version => 1).redact!(create(:redaction))

      get api_way_version_path(way, 1), :headers => bearer_authorization_header

      assert_response :forbidden, "Redacted way shouldn't be visible via the version API, even when logged in."

      get api_way_version_path(way, 1, :show_redactions => "true"), :headers => bearer_authorization_header

      assert_response :forbidden, "Redacted way shouldn't be visible via the version API, even when logged in and passing flag."
    end

    def test_show_redacted_moderator
      way = create(:way, :with_history, :version => 2)
      way.old_ways.find_by(:version => 1).redact!(create(:redaction))
      auth_header = bearer_authorization_header create(:moderator_user)

      get api_way_version_path(way, 1), :headers => auth_header

      assert_response :forbidden, "Redacted node should be gone for moderator, when flag not passed."

      get api_way_version_path(way, 1, :show_redactions => "true"), :headers => auth_header

      assert_response :success, "Redacted node should not be gone for moderator, when flag passed."
    end

    ##
    # check that returned history is the same as getting all
    # versions of a way from the api.
    def test_history_equals_versions
      way = create(:way, :with_history)
      used_way = create(:way, :with_history)
      create(:relation_member, :member => used_way)
      way_with_versions = create(:way, :with_history, :version => 4)

      check_history_equals_versions(way.id)
      check_history_equals_versions(used_way.id)
      check_history_equals_versions(way_with_versions.id)
    end

    ##
    # test the redaction of an old version of a way, while not being
    # authorised.
    def test_redact_way_unauthorised
      do_redact_redactable_way
      assert_response :unauthorized, "should need to be authenticated to redact."
    end

    ##
    # test the redaction of an old version of a way, while being
    # authorised as a normal user.
    def test_redact_way_normal_user
      do_redact_redactable_way bearer_authorization_header
      assert_response :forbidden, "should need to be moderator to redact."
    end

    ##
    # test that, even as moderator, the current version of a way
    # can't be redacted.
    def test_redact_way_current_version
      way = create(:way, :with_history, :version => 2)
      redaction = create(:redaction)
      auth_header = bearer_authorization_header create(:moderator_user)

      post way_version_redact_path(way, 2), :params => { :redaction => redaction.id }, :headers => auth_header

      assert_response :bad_request, "shouldn't be OK to redact current version as moderator."
    end

    def test_redact_way_by_regular_without_write_redactions_scope
      auth_header = bearer_authorization_header(create(:user), :scopes => %w[read_prefs write_api])
      do_redact_redactable_way(auth_header)
      assert_response :forbidden, "should need to be moderator to redact."
    end

    def test_redact_way_by_regular_with_write_redactions_scope
      auth_header = bearer_authorization_header(create(:user), :scopes => %w[write_redactions])
      do_redact_redactable_way(auth_header)
      assert_response :forbidden, "should need to be moderator to redact."
    end

    def test_redact_way_by_moderator_without_write_redactions_scope
      auth_header = bearer_authorization_header(create(:moderator_user), :scopes => %w[read_prefs write_api])
      do_redact_redactable_way(auth_header)
      assert_response :forbidden, "should need to have write_redactions scope to redact."
    end

    def test_redact_way_by_moderator_with_write_redactions_scope
      auth_header = bearer_authorization_header(create(:moderator_user), :scopes => %w[write_redactions])
      do_redact_redactable_way(auth_header)
      assert_response :success, "should be OK to redact old version as moderator with write_redactions scope."
    end

    ##
    # test the redaction of an old version of a way, while being
    # authorised as a moderator.
    def test_redact_way_moderator
      way = create(:way, :with_history, :version => 2)
      old_way = way.old_ways.find_by(:version => 1)
      redaction = create(:redaction)
      auth_header = bearer_authorization_header create(:moderator_user)

      post way_version_redact_path(*old_way.id), :params => { :redaction => redaction.id }, :headers => auth_header

      assert_response :success, "should be OK to redact old version as moderator."
      old_way.reload
      assert_predicate old_way, :redacted?
      assert_equal redaction, old_way.redaction
    end

    ##
    # test the unredaction of an old version of a way, while not being
    # authorised.
    def test_unredact_way_unauthorised
      way = create(:way, :with_history, :version => 2)
      old_way = way.old_ways.find_by(:version => 1)
      redaction = create(:redaction)
      old_way.redact!(redaction)

      post way_version_redact_path(*old_way.id)

      assert_response :unauthorized, "should need to be authenticated to unredact."
      assert_equal redaction, old_way.reload.redaction
    end

    ##
    # test the unredaction of an old version of a way, while being
    # authorised as a normal user.
    def test_unredact_way_normal_user
      way = create(:way, :with_history, :version => 2)
      old_way = way.old_ways.find_by(:version => 1)
      redaction = create(:redaction)
      old_way.redact!(redaction)
      auth_header = bearer_authorization_header

      post way_version_redact_path(*old_way.id), :headers => auth_header

      assert_response :forbidden, "should need to be moderator to unredact."
      assert_equal redaction, old_way.reload.redaction
    end

    ##
    # test the unredaction of an old version of a way, while being
    # authorised as a moderator.
    def test_unredact_way_moderator
      moderator_user = create(:moderator_user)
      way = create(:way, :with_history, :version => 2)
      old_way = way.old_ways.find_by(:version => 1)
      old_way.redact!(create(:redaction))
      auth_header = bearer_authorization_header moderator_user

      post way_version_redact_path(*old_way.id), :headers => auth_header

      assert_response :success, "should be OK to unredact old version as moderator."
      assert_nil old_way.reload.redaction
    end

    private

    ##
    # look at all the versions of the way in the history and get each version from
    # the versions call. check that they're the same.
    def check_history_equals_versions(way_id)
      get api_way_versions_path(way_id)
      assert_response :success, "can't get way #{way_id} from API"
      history_doc = XML::Parser.string(@response.body).parse
      assert_not_nil history_doc, "parsing way #{way_id} history failed"

      history_doc.find("//osm/way").each do |way_doc|
        history_way = Way.from_xml_node(way_doc)
        assert_not_nil history_way, "parsing way #{way_id} version failed"

        get api_way_version_path(way_id, history_way.version)
        assert_response :success, "couldn't get way #{way_id}, v#{history_way.version}"
        version_way = Way.from_xml(@response.body)
        assert_not_nil version_way, "failed to parse #{way_id}, v#{history_way.version}"

        assert_ways_are_equal history_way, version_way
      end
    end

    def do_redact_redactable_way(headers = {})
      way = create(:way, :with_history, :version => 2)
      redaction = create(:redaction)

      post way_version_redact_path(way.id, 1), :params => { :redaction => redaction.id }, :headers => headers
    end
  end
end
