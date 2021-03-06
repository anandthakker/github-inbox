# frozen_string_literal: true
require 'test_helper'

class NotificationTest < ActiveSupport::TestCase
  setup { stub_notifications_request }

  test '#download fetches one months notification when a user has not been synched before' do
    travel_to "2016-12-19T19:00:00Z" do
      user = users(:andrew)
      user.last_synced_at = nil

      Notification.download(user)

      assert_requested :get, "https://api.github.com/notifications?all=true&per_page=100&since=2016-11-19T19:00:00Z"
    end
  end

  test '#download only fetches notifications updated since the last sync' do
    user = users(:andrew)
    user.last_synced_at = "2016-12-19T19:00:00Z"

    Notification.download(user)

    assert_requested :get, "https://api.github.com/notifications?all=true&per_page=100&since=2016-12-19T19:00:00Z"
  end

  test "#download will set the url for a Repository invitation correctly" do
    stub_notifications_request(body: file_fixture('repository_invitation_notification.json'))
    user = users(:andrew)

    Notification.download(user)

    assert notification = Notification.last
    assert_equal 'RepositoryInvitation', notification.subject_type
    assert_match %r{https://github.com/.+/invitations$}, notification.subject_url
  end

  private

  def stub_notifications_request(body: nil)
    notifications_url = %r{https://api.github.com/notifications}

    body     ||= file_fixture('notifications.json')
    headers  = { 'Content-Type' => 'application/json' }
    response = { status: 200, body: body, headers: headers }

    stub_request(:get, notifications_url).to_return(response)
  end
end
