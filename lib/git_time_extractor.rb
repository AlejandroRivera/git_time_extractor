#
# Extract Reasonable Developer Time Records from a GIT Repository's Commit Log
#
# This is inspired by a RAKE task publicly posted by Sharad at 
# http://www.tatvartha.com/2010/01/generating-time-entry-from-git-log/. 
# However, it has been adapted to run without Rails from the command line.
#
# Portions (C) 2012 Rietta Inc. and licensed under the terms of the BSD license.
#
class GitTimeExtractor
  VERSION = '0.2.2'
  
  require 'rubygems'
  require 'ostruct'
  require 'logger'
  require 'git'
  require 'csv'
  require 'set'

  #
  # Go through the GIT commit log, to compute the elapsed working time of each committing developer, based
  # on a few assumptions:
  #
  # (1) A series of commits within a 3 hour window are part of the same development session
  # (2) A single commit (or the first commit of the session) is considered to represent 30 minutes of work time
  # (3) The more frequent a developer commits to the repository while working, the more accurate the time report will be
  #
  #
  def self.process_git_log_into_time(path_to_git_repo = "./", path_to_output_file = "-", project_name = "")

    if "-" != path_to_output_file
      raise "Output path not yet implemented. Use a Unix pipe to write to your desired file. For example: git_time_extractor ./ > my_result.csv\n" 
    end 
    
    # Open the GIT Repository for Reading
    logger = Logger.new(STDOUT)
    logger.level = Logger::WARN
    g = Git.open(path_to_git_repo, :log => logger)
    logs = g.log(1000)
    log_entries = logs.entries.reverse
    worklog = {}

    # Go through the GIT commit records and construct the time
    log_entries.each_with_index do |commit, index|
      author_date = commit.author_date.to_date
      daylog = worklog[author_date] || OpenStruct.new(:date => author_date, :duration => 0, :commit_count => 0, :pivotal_stories => Set.new )
      daylog.author = commit.author
      daylog.message = "#{daylog.message} --- #{commit.message}"
      daylog.duration = daylog.duration + calc_duration_in_minutes(log_entries, index)
      
      # The git commit count
      daylog.commit_count += 1
      
      # Pivotal Stories
      stories = pivotal_ids(commit.message)
      if stories
        # It's a set, so each story only gets added once per day
        stories.each do |sid|
          daylog.pivotal_stories << sid
        end
      end
      
      
      worklog[author_date] = daylog
    end # log_entries.each_with_index

    # Print the header row for the CSV
    puts [
        'Date',
        'Git Commits Count',
        'Pivotal Stories Count',
        'Minutes',
        'Hours',
        'Person',
        'Email',
        'Project',
        'Notes',
        'Pivotal Stories',
        'Week Number',
        'Year'
        ].to_csv

    # Go through the work log  
    worklog.keys.sort.each do |date|
        summary = worklog[date]
        start_time = DateTime.parse(date.to_s)
        duration_in_seconds = (summary.duration.to_f * 60.0).round(0)
        duration_in_minutes = summary.duration.to_i
        duration_in_hours = (summary.duration / 60.0).round(1)

        stop_time = start_time + duration_in_seconds
        
        row = [
              start_time.strftime("%m/%d/%Y"),
              summary.commit_count,
              summary.pivotal_stories.count,
              duration_in_minutes,
              duration_in_hours,
              summary.author.name,
              summary.author.email,
              project_name,
              summary.message,
              summary.pivotal_stories.map(&:inspect).join('; '),
              start_time.strftime("%W").to_i,
              start_time.strftime("%Y").to_i]
        puts row.to_csv
    end # worklog each

  end # process_git_log_into_time
  
  # Calculate the duration of work in minutes
  def self.calc_duration_in_minutes(log_entries, index)
    commit = log_entries[index]
    if index > 1
      previous_commit = log_entries[index-1]
      # Default duration in Ruby is in seconds
      duration = commit.author_date - previous_commit.author_date
      
      # ASSUMPTION: if the gap between 2 commits is more than 3 hours, reduce it to 1/2 hour
      # Also, if the time is negative then this is usually a merge operation.  Assume the developer spent
      # 30 minutes reviewing it
      duration = 30 * 60 if duration < 0 || duration > 3 * 3600
    else
      # ASSUMPTION: first commit took 1/2 hour
      duration = 30 * 60
    end
    return duration.to_f / 60.0
  end # calc_duration_in_minutes

  def self.say_hi
    "hi"
  end
  
  #  --- [#62749778] New Email Page --- Merge branch 'development' of bitbucket.org:rietta/roofregistry-web into development --- [#62749778] Roughed out email form. --- Added delete Attachment functionality --- Merge branch 'development' of bitbucket.org:rietta/roofregistry-web into development --- [#62749778] Refactored controller to be plural. --- [#62749778] Added to the Email model. --- [62749778] The email this report view formatting. --- [#62749778] Breadcrumbs in the navigation. --- [#62749778] The Emails controller routes. --- The report list is now sorted with newest first - and it shows how long ago that the change was made. --- [#62749778] The share link is bold. --- [#62749778] Recipient parsing and form fields --- [#62749778] List of emails that have received it. --- [#62749778] The email form will validate that at least one email is provided. --- [#62749778] Send Roof Report AJAX form. --- [#62749778] Default messages and the mailer --- [Finishes #62749778] The emails are sent! --- removed delete from show --- added txt and xpf to permitted file types --- Attachments can only be deleted by the owner of the roof report. --- Merge branch 'development' of bitbucket.org:rietta/roofregistry-web into development --- The test server is using production. --- Returns all recommended options across all sections with roof_report.recommedations --- patial commit --- Finished summary section --- Added caps to permitted --- added to_s to inspection --- E-mail spec is not focused at the moment. --- Merge branch 'development' of bitbucket.org:rietta/roofregistry-web into development --- fixed a few bugs --- Merge branch 'development' of bitbucket.org:rietta/roofregistry-web into development --- Disable ajax save. --- Merge branch 'development' of bitbucket.org:rietta/roofregistry-web into development
  # s = "[#62749778] [#62749778] [#6274977] [#1] [#231]"
  # m = s.scan /\[[A-Za-z ]{0,20}#[0-9]{1,20}\]/
  def self.pivotal_ids(text)
    stories = Array.new
    # Extract the unique ids between brackets
    if text
      candidates = text.scan /\[[A-Za-z \t]{0,20}#[0-9]{1,35}[ \t]{0,5}\]/
      if candidates
        candidates.uniq.each do |story|
          story_num = story.match(/[0-9]{1,35}/).to_s.to_i
          stories << story_num if story_num > 0
        end
      end
    end
    stories.sort
  end
end # class GitTimeExtractor
