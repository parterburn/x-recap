class XBookmark < ActiveRecord::Base
  belongs_to :user

  validates :tweet_id, presence: true, uniqueness: { scope: :user_id }

  scope :recent, -> { order(tweeted_at: :desc) }
  scope :since, ->(time) { where("tweeted_at >= ?", time) }

  def to_s
    "#{tweeted_at.strftime('%A, %B %-d, %Y')} — #{author_name} (#{author_username}):\n#{text}\n\n#{tweet_url}\n\n#{entities.to_json}\n\n#{public_metrics.to_json}"
  end

  def tweet_url
    url || "https://x.com/#{author_username}/status/#{tweet_id}"
  end

  def self.human_count(n)
    n = n.to_i
    if n >= 1_000_000
      "#{(n / 1_000_000.0).round(1).to_s.sub(/\.0$/, '')}M"
    elsif n >= 1_000
      "#{(n / 1_000.0).round(n >= 10_000 ? 0 : 1).to_s.sub(/\.0$/, '')}k"
    else
      n.to_s
    end
  end

  # Syncs latest N bookmarks from X API for a user. Skips duplicates.
  def self.sync_for_user!(user, max_results: 30)
    client = XApiClient.new(user: user)
    result = client.bookmarks(max_results: max_results)
    tweets = result["data"]
    return 0 unless tweets.present?

    authors = (result.dig("includes", "users") || []).index_by { |u| u["id"] }
    new_count = 0

    tweets.each do |tweet|
      next if user.x_bookmarks.exists?(tweet_id: tweet["id"])

      author = authors[tweet["author_id"]] || {}
      new_bookmark = user.x_bookmarks.create!(
        tweet_id: tweet["id"],
        author_id: tweet["author_id"],
        author_username: author["username"],
        author_name: author["name"],
        text: tweet["text"],
        tweeted_at: tweet["created_at"],
        url: "https://x.com/#{author['username']}/status/#{tweet['id']}",
        entities: tweet["entities"] || {},
        public_metrics: tweet["public_metrics"] || {}
      )
      RaindropClient.save(new_bookmark) if user.raindrop_api_key.present?
      new_count += 1
    end

    new_count
  end
end
