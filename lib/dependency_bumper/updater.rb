# frozen_string_literal: true

require 'dependency_bumper/bundler/cli/outdated'

module DependencyBumper
  class Updater
    attr_reader :config, :use_git, :report

    def initialize(config = {}, use_git = false)
      @config = config
      @use_git = use_git
    end

    def run
      commands = generate_update_arguments(outdated_gems)
      options = { 'jobs' => Etc.nprocessors }

      @report = report_result do
        commands.each do |group, gems|
          Bundler.settings.temporary(no_install: false) do
            Bundler::CLI::Update.new(options.merge({ group => true }), gems).run
          end
        end
      end

      if report.empty?
        Console.logger.info('No gem updated')
      else
        Console.logger.info(report)
        create_git_branch(report) if use_git
      end
    end

    def create_git_branch(report)
      branch_name = "gem-bump-#{Time.now.strftime('%d-%m-%Y')}"
      repo_path = exec(['git', 'rev-parse', '--show-toplevel']).first.strip
      git_repo = Git.open(repo_path, log: Console.logger)

      git_config_username_email(git_repo)
      git_repo.checkout(branch_name, new_branch: true)

      output = <<~END
        Updating gems #{Time.now.strftime('%d-%m-%Y')}
        #{report}
      END

      git_repo.add(all: true)
      git_repo.commit(output)
    rescue Git::GitExecuteError => error
      Console.logger.error(error)
    end

    def git_config_username_email(repo)
      if repo.config['user.email'].nil? || repo.config['user.name'].nil?
        Console.logger.info('Setting up temporary username and email for committing please update git config')
        repo.config('user.name', 'Your name')
        repo.config('user.email', 'you@example.com')
      else
        Console.logger.info('User name and email is set, read to commit')
      end
      repo.config('commit.gpgsign', config.dig('git', 'commit', 'gpgsign').to_s)
    end

    def report_result
      master_lockfile = Bundler::LockfileParser.new(Bundler.read_file(current_gem_file))

      gems = {}

      master_lockfile.specs.each do |spec|
        gems[spec.name] = { from: spec.version }
      end

      yield

      updated_lockfile = Bundler::LockfileParser.new(Bundler.read_file(current_gem_file))

      updated_lockfile.specs.each do |spec|
        gems[spec.name][:to] = spec.version if gems[spec.name]
      end

      output = ''
      gems.each do |k, v|
        next if v[:from] == v[:to]

        message = "#{k} From #{v[:from]} To #{v[:to]} update level: #{major_minor_patch(v[:from], v[:to])} \n"
        output += message
      end

      output
    end

    def major_minor_patch(old_version, new_version)
      old_versions = old_version.canonical_segments
      new_versions = new_version.canonical_segments

      if new_versions[0] - old_versions[0] > 1
        return :major
      else # check cases like 1.9 to 2.0
        return :major if new_versions[1].nil? || new_versions[1].nil?

        return :minor if new_versions[1] < old_versions[1]
      end

      if new_versions[1] - old_versions[1] > 1
        return :minor
      else
        return :patch if new_versions[2].nil? || new_versions[2].nil?

        return :patch if new_versions[2] < old_versions[2]
      end

      return :patch if new_versions[2] - old_versions[2] >= 1
    end

    private

    def current_gem_file
      Bundler::SharedHelpers.default_lockfile
    end

    def outdated_gems
      bundler = Bundler::CLI::Outdated.new({ convert_outdated_level => true, parseable: true }, [])
      outdated_gems_list = bundler.run

      if outdated_gems_list == []
        Console.logger.info('No outdated gems found')

        exit 1
      end

      outdated_gems_list.map { |gem| gem[:current_spec].name }
    end

    def convert_outdated_level
      {
        'strict' => 'filter-strict',
        'patch' => 'filer-patch',
        'minor' => 'filter-minor',
        'major' => 'filter-major',
      }.fetch(config['outdated_level'], 'filter-strict')
    end

    def exec(cmd)
      result = []
      Open3.popen3(*cmd) do |_, stdout, stderr, wait_thr|
        stdout.each_line do |x|
          Console.logger.info(x)

          next if x.match?(/^\n$/)

          result << x
        end

        stderr.each do |x|
          Console.logger.error(x)
        end

        exit_status = wait_thr.value # Process::Status object returned.
        Console.logger.debug("exit status: #{exit_status.success?}")
      end

      result
    end

    def generate_update_arguments(gem_names)
      grouped_gems = {
        'major' => [],
        'minor' => [],
        'patch' => [],
      }

      gem_names.each do |gem_name|
        next if config['skip'].key?(gem_name)

        placed_in_group = false

        grouped_gems.keys.each do |group_name|
          if config['update'][group_name].key?(gem_name)
            grouped_gems[group_name] << gem_name
            placed_in_group = true
          end
        end

        unless placed_in_group
          grouped_gems[config['update']['default']] << gem_name
        end
      end

      grouped_gems.reject! { |_, v| v.empty? }

      grouped_gems
    end
  end
end
