#! /usr/bin/env ruby

require "yaml"

class ActionsManifest
  def initialize(file)
    @config ||= YAML.load_file(file)
  end

  def matrix_for(job_name)
    Matrix.new(
      @config.dig('jobs', job_name, 'strategy', 'matrix')
    )
  end
end

class Matrix
  def initialize(matrix)
    @matrix = matrix
  end

  def each_pair
    @matrix["include"].each do |incl|
      yield incl["ruby-version"], incl["rails-version"]
    end
  end

  def ruby_versions
    @matrix["include"].map { |incl| incl["ruby-version"] }
  end

  def rails_versions
    @matrix["include"].map { |incl| incl["rails-version"] }
  end
end

class Task
  def initialize(env, cmd, tags = {}, include_in_results: true)
    @env = env
    @cmd = cmd
    @tags = tags
    @include_in_results = include_in_results
    @exit_status = -1
  end

  def include_in_results?
    @include_in_results
  end

  def execute(prefix)
    puts "#{prefix}#{env_str} #{@cmd}"
    system(@env, @cmd)
    @exit_status = $?.exitstatus
    nil
  end

  def success?
    @exit_status == 0
  end

  def slug
    @slug ||= @tags.map { |k, v| "#{k}=#{v}" }.join(" ")
  end

  private

  def env_str
    @env_str ||= @env
      .filter_map { |k, v| k == "PATH" ? nil : "#{k}=#{v}" }
      .join(" ")
  end
end

class Runner
  def initialize
    @queue = []
  end

  def enqueue_rails(ruby_version, rails_version, cmd, **kwargs)
    enqueue(ruby_version, rails_version, cmd, { "BUNDLE_GEMFILE" => "gemfiles/rails_#{rails_version}.gemfile" }, **kwargs)
  end

  def enqueue_ruby(ruby_version, cmd, **kwargs)
    enqueue(ruby_version, nil, cmd, { "BUNDLE_GEMFILE" => "gemfiles/ruby.gemfile" }, **kwargs)
  end

  def execute_all!
    @queue.each_with_index do |task, idx|
      task.execute("(#{idx + 1}/#{@queue.size}) ")
    end

    @queue.dup.tap { @queue.clear }
  end

  private

  def installed_ruby_versions_by_minor
    @installed_ruby_versions_by_minor ||= `asdf list ruby`
      .split("\n")
      .map { |v| v.sub("*", "").strip }
      .select { |v| v =~ /\A\d\.\d+\.\d+\z/ }
      .group_by { |v| v.split(".")[0...2].join(".") }
      .each_with_object({}) do |(minor, versions), memo|
        memo[minor] = versions.sort.last
      end
  end

  def enqueue(ruby_version, rails_version, cmd, env = {}, include_in_results: true)
    asdf_ruby_version = installed_ruby_versions_by_minor[ruby_version]
    env["ASDF_RUBY_VERSION"] = asdf_ruby_version
    install_path = `asdf where ruby #{asdf_ruby_version}`.strip
    env["PATH"] = "#{File.join(install_path, "bin")}:#{ENV["PATH"]}"
    tags = { "ruby-version" => ruby_version }
    tags["rails-version"] = rails_version if rails_version
    @queue << Task.new(env, cmd, tags, include_in_results: include_in_results)
  end
end

actions = ActionsManifest.new(".github/workflows/test.yml")
runner = Runner.new

actions.matrix_for("build_rails").each_pair do |ruby_version, rails_version|
  runner.enqueue_rails(
    ruby_version,
    rails_version,
    "bundle check || bundle install",
    include_in_results: false
  )

  runner.enqueue_rails(
    ruby_version,
    rails_version,
    "bundle exec rake spec:rails"
  )
end

actions.matrix_for("build_ruby").ruby_versions.each do |ruby_version|
  runner.enqueue_ruby(
    ruby_version,
    "bundle check || bundle install",
    include_in_results: false
  )

  runner.enqueue_ruby(
    ruby_version,
    "bundle exec rake spec:ruby"
  )
end

def red(str)
  "\u001b[31m#{str}\u001b[0m"
end

def green(str)
  "\u001b[32m#{str}\u001b[0m"
end

tasks = runner.execute_all!

tasks.each do |task|
  next unless task.include_in_results?
  puts "#{task.slug}: #{task.success? ? green("SUCCEEDED") : red("FAILED")}"
end
