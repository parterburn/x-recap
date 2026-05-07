class User < ActiveRecord::Base
  has_many :x_bookmarks, dependent: :destroy

  validates :email, presence: true, uniqueness: true

  TOKEN_URL = "https://api.x.com/2/oauth2/token"

  def x_connected?
    x_refresh_token.present?
  end

  def disconnect_x!
    update!(x_access_token: nil, x_refresh_token: nil, x_uid: nil, x_username: nil)
  end

  # Returns a fresh access token, refreshing if needed.
  def fresh_x_access_token!
    return nil unless x_connected?

    refresh_x_tokens!
    x_access_token
  end

  private

  def refresh_x_tokens!
    conn = Faraday.new(TOKEN_URL) do |f|
      f.request :url_encoded
      f.response :json
    end

    basic = Base64.strict_encode64("#{ENV.fetch('X_CLIENT_ID')}:#{ENV.fetch('X_CLIENT_SECRET')}")
    resp = conn.post("", { grant_type: "refresh_token", refresh_token: x_refresh_token }) do |req|
      req.headers["Authorization"] = "Basic #{basic}"
    end

    if resp.success?
      update!(x_access_token: resp.body["access_token"], x_refresh_token: resp.body["refresh_token"])
    else
      warn "X token refresh failed (status=#{resp.status}): #{resp.body.inspect}"
      nil
    end
  end
end
