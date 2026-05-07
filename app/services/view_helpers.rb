# Tiny replacements for the ActionView helpers used in the digest template
# (pluralize, simple_format, truncate). Avoids pulling all of ActionView in
# for a single ERB file.
module ViewHelpers
  module_function

  def pluralize(count, singular, plural = nil)
    word = count == 1 ? singular : (plural || singular + "s")
    "#{count} #{word}"
  end

  def simple_format(text)
    return "" if text.nil?

    paragraphs = text.to_s.gsub("\r\n", "\n").split(/\n\n+/)
    paragraphs.map! { |p| "<p>#{p.strip.gsub("\n", "<br/>\n")}</p>" }
    paragraphs.join("\n\n")
  end

  def truncate(text, length: 30, omission: "...")
    return "" if text.nil?
    s = text.to_s
    return s if s.length <= length
    s[0, length - omission.length].rstrip + omission
  end

  # Renders an ERB template at app/views/<path>.html.erb with the given local
  # variables made available as instance variables on the context.
  def render(view_path, **assigns)
    full_path = File.join(APP_ROOT, "app/views", "#{view_path}.html.erb")
    template = File.read(full_path)
    context = Class.new do
      include ViewHelpers
    end.new
    assigns.each { |k, v| context.instance_variable_set("@#{k}", v) }
    ERB.new(template, trim_mode: "-").result(context.instance_eval { binding })
  end
end
