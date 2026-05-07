# Minimal Mailgun HTTP API client. We only need the messages endpoint.
class MailgunClient
  BASE_URL = "https://api.mailgun.net"

  def self.send_message(from:, to:, subject:, html:, tag: nil)
    domain = ENV.fetch("SMTP_DOMAIN")
    api_key = ENV.fetch("MAILGUN_API_KEY")

    conn = Faraday.new(BASE_URL) do |f|
      f.request :url_encoded
      f.response :json
      f.request :authorization, :basic, "api", api_key
    end

    body = {
      from: from,
      to: to,
      subject: subject,
      html: html
    }
    body["o:tag"] = tag if tag

    resp = conn.post("/v3/#{domain}/messages", body)
    raise "Mailgun send failed (status=#{resp.status}): #{resp.body.inspect}" unless resp.success?
    resp.body
  end
end
