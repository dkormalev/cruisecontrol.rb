module BuildsHelper

  def select_builds(builds)
    return "" if builds.blank?

    options = builds.map do |build|
      "<option value='#{build.label}'>#{build_to_text(build, false)}</option>"
    end
    options.unshift "<option value=''>Older Builds...</option>"
    
    select_tag "build", options.join, :onChange => "this.form.submit();"
  end
  
  def format_build_log(log)
    strip_ansi_colors(highlight_test_count(link_to_code(h(log))))
  end
  
  def format_changeset_log_pretty(log)
      link_changeset_to_code(link_to_emails(link_to_repository(h(log.strip))))
  end
  
  def link_to_repository(log)
    unless @project.tracker_web_url && @project.repository_url_addition
      return log
    end
    log.gsub(/Revision (\w+)/) do |match|
      revision = $1
      url = @project.tracker_web_url + @project.repository_url_addition.gsub(/REVISION_ID/, revision)
      result = "Revision <a href='#{url}'>#{revision}</a>"
      result
    end
  end
  
  def link_to_emails(log)
    log.gsub(/&lt;([A-Z0-9._%+-]+@(?:[A-Z0-9-]+\.)+(?:[A-Z]{2}|com|org|net|edu|gov|mil|biz|info|mobi|name|aero|asia|jobs|museum))&gt;/i, '<a href="mailto:\1">\0</a>')
  end

  def link_changeset_to_code(log)
    @work_path ||= File.expand_path(@project.path + '/work')
    
    log.gsub(/^\s*([\w-]*\/[ \w\/\.-]+[\w\.-])/) do |match|
      path = File.expand_path($1, @work_path)
      if path.index(@work_path) == 0
        path = path[@work_path.size..-1]
        link_to match, "/projects/code/#{h @project.name}#{path}"
      else
        match
      end
    end
  end  
  
  def link_to_code(log)
    return log if Configuration.disable_code_browsing
    @work_path ||= File.expand_path(@project.path + '/work')
    
    log.gsub(/(\#\{RAILS_ROOT\}\/)?([\w\.-]*\/[ \w\/\.-]+)\:(\d+)/) do |match|
      line = $3
      truncated_path = $2.gsub(/^(\.\.(\/)?)*/, "")
      path = File.expand_path(truncated_path, @work_path)
      line = $3
      if path.index(@work_path) == 0
        path = path[@work_path.size..-1]
        link_to match, "/projects/code/#{h @project.name}#{path}?line=#{line}##{line}"
      else
        match
      end
    end
  end
  
  def format_project_settings(settings)
    settings = settings.strip
    if settings.empty?
      "This project has no custom configuration. Maybe it doesn't need it.<br/>" +
      "Otherwise, #{link_to('the manual', document_path('manual'))} can tell you how."
    else
      h(settings)
    end
  end
  
  def failures_and_errors_if_any(log)
    errors = BuildLogParser.new(log).failures_and_errors
    return nil if errors.empty?
    
    link_to_code(errors.collect{|error| format_test_error_output(error)}.join)
  end
  
  def format_test_error_output(test_error)
    message = test_error.message

    "Name: #{test_error.test_name}\n" +
    "Type: #{test_error.type}\n" +
    "Message: #{h message}\n\n" +
    "<span class=\"error\">#{h test_error.stacktrace}</span>\n\n\n"
  end

  def display_build_time
    if @build.incomplete?
      if @build.latest?
        "building for #{format_seconds(@build.elapsed_time_in_progress, :general)}"
      else
        "started at #{format_time(@build.time, :verbose)}, and never finished"
      end
    else
      elapsed_time_text = elapsed_time(@build, :precise)
      build_time_text = format_time(@build.time, :verbose)
      elapsed_time_text.empty? ? "finished at #{build_time_text}" : "finished at #{build_time_text} taking #{elapsed_time_text}"
    end
  end

  private

  def highlight_test_count(log)
    log.gsub(/\d+ tests, \d+ assertions, \d+ failures, \d+ errors/, '<div class="test-results">\0</div>').
        gsub(/\d+ examples, \d+ failures/, '<div class="test-results">\0</div>').
        gsub(/^.*(Warning:|Error:|Permission denied).*$/i, '<span class="build-errors">\0</span>').
        gsub(/^-{5,}.*-{5,}$/i, '<span class="build-section">\0</span>')        
  end

  def strip_ansi_colors(log)
    log.gsub(/\e\[\d+m/, '')
  end
end