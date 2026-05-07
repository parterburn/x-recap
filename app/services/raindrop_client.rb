# Optional: pushes a saved bookmark to Raindrop.io if the user has an API key.
class RaindropClient
  BASE_URL = "https://api.raindrop.io"

  def self.save(bookmark)
    return unless bookmark.user.raindrop_api_key.present?

    conn = Faraday.new(BASE_URL) do |f|
      f.request :json
      f.response :json
      f.headers["Authorization"] = "Bearer #{bookmark.user.raindrop_api_key}"
    end

    conn.post("/rest/v1/raindrop", {
      link: bookmark.tweet_url,
      title: "#{bookmark.author_name} on X: #{bookmark.text.to_s.split("\n").first.to_s[0, 80]}",
      excerpt: bookmark.text,
      tags: ["x-bookmarks"],
      pleaseParse: {}
    })
  rescue => e
    warn "Raindrop save failed for tweet #{bookmark.tweet_id}: #{e.message}"
  end
end
