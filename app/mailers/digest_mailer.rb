# Builds + sends the monthly X bookmarks digest email via Mailgun.
class DigestMailer
  def self.send_summary!(user:, since: DateTime.now.beginning_of_month)
    bookmarks = user.x_bookmarks.where(created_at: since..).recent
    return :no_bookmarks unless bookmarks.any?

    summary = AiBookmarkSummarizer.new.summarize!(bookmarks: bookmarks)

    html = ViewHelpers.render("digest_mailer/summary",
                              user: user,
                              bookmarks: bookmarks,
                              summary: summary)

    subject = "#{ViewHelpers.pluralize(bookmarks.count, 'bookmark')} this month"

    MailgunClient.send_message(
      from: ENV.fetch("FROM_EMAIL"),
      to: user.email,
      subject: subject,
      html: html,
      tag: "XRecapSummary"
    )

    bookmarks.count
  end
end
