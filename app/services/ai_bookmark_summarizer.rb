class AiBookmarkSummarizer
  def summarize!(bookmarks:)
    @bookmarks = bookmarks
    return nil unless @bookmarks.any?

    chat = RubyLLM.chat(model: model)
                  .with_instructions(developer_prompt)
                  .with_params(
                    reasoning_effort: "medium"
                  )

    response = chat.ask(user_prompt)
    response&.content
  end

  private

  def model
    validate_llm_config!
    ENV.fetch("AI_MODEL")
  end

  def validate_llm_config!
    raise "AI_MODEL must be set" if ENV["AI_MODEL"].blank?

    return if ENV["XAI_API_KEY"].present? || ENV["OPENAI_API_KEY"].present?

    raise "Set XAI_API_KEY or OPENAI_API_KEY for AiBookmarkSummarizer"
  end

  def developer_prompt
    %(Role: You turn batches of X bookmarks into a scannable HTML briefing for email.

Goal:
Summarize the most useful patterns, notable posts, and overlooked insights from the provided bookmarks. The reader will see the full bookmarks below your summary, so focus on triage, not reproduction.

Input:
Bookmarks are separated by "######".

Each bookmark includes:
- tweeted_at
- author_name
- author_username
- text
- tweet_url
- entities JSON
- public_metrics JSON

Output:
Return raw HTML only.

Allowed tags:
<p>, <b>, <i>, <a>, <ul>, <li>, <h3>

Do not use markdown.
Do not use code fences.
Do not output raw URLs. Always use descriptive linked text.

Sections:
Include only sections that have relevant items. Keep this exact order.

<h3>Themes</h3>
<ul>
  <li>1 to 4 short bullets identifying recurring patterns, topics, or shifts across the batch.</li>
</ul>

Rules:
- No individual tweet links in this section.
- Do not force themes if the batch is too scattered.

<h3>Most Engagement</h3>
<ul>
  <li><a href="tweet_url"><b>Short descriptive title</b></a> — @author_handle<br>One short note explaining why it matters.</li>
</ul>

Rules:
- Include up to 5 tweets.
- Rank by a mix of engagement, timeliness, and strategic relevance.
- Use public_metrics to inform ranking, but do not say generic things like “high likes” or “many retweets.”
- Explain the actual substance: why this is useful, surprising, actionable, or strategically relevant.

<h3>Wildcards</h3>
<ul>
  <li><a href="tweet_url"><b>Short descriptive title</b></a> — @author_handle<br>One short note explaining the unusual insight.</li>
</ul>

Rules:
- Include 1 to 2 low-metric posts only when they are unusually novel, insightful, or underappreciated.
- Skip this section if there are no strong candidates.

Sparse-batch rule:
If the batch contains fewer than 3 useful bookmarks, produce only the strongest applicable sections and do not pad the briefing.

Hard rules:
- Each tweet may appear in only one section.
- Never duplicate a tweet across sections.
- Do not reproduce tweet text verbatim.
- Summarize each tweet in a few words or one short sentence.
- Deprioritize memes, vague hot takes, engagement bait, and duplicate ideas.
- Prefer posts that are timely, practical, strategically relevant, or unusually clear.
- Keep the briefing highly scannable: short bullets, bold key phrases, minimal prose.

Style:
Crisp, practical, editorial.
No filler.
No generic praise.
No “this tweet discusses...” phrasing.)
  end

  def user_prompt
    "Here are my #{ViewHelpers.pluralize(@bookmarks.count, 'X bookmark')}:\n\n" \
      "#{@bookmarks.map(&:to_s).join("\n\n######\n\n")}"
  end
end
