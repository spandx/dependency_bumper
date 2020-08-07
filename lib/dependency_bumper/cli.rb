# frozen_string_literal: true

module DependencyBumper
  class Cli < Thor
    DEFAULT_CONFIGURATION = {
      'skip' => {},
      'outdated_level' => 'strict',
      'update' => {
        'default' => 'minor',
        'major' => {},
        'minor' => {},
        'patch' => {}
      },
      'git' => {
        'commit' => {
          'gpgsign' => false
        }
      }
    }.freeze

    package_name 'Dependency Bumper'

    option :config, type: :string
    option :git, type: :boolean
    option :dry, type: :boolean
    desc 'bump_gems', 'update dependencies of your Ruby project'
    long_desc <<-LONGDESC
     `bump_gems` will update dependencies of your Ruby project

    If you give --git option it will create a branch and commit message will include information about updated gems.

    --dry option will change Gemfile.lock but won't install gems.

    This gem looks for a config file called bumper_config.json by default and if it doesn't find it, it will use default

    configuration. You can point out another folder for configuration.

    Examples \n
    > $ dbump bump_gems --git --config myconfig.json \n
    > $ dbump bump_gems --dry \n
    > $ dbump bump_gems \n

    LONGDESC

    def bump_gems
      path = options.fetch(:config, '.bumper_config.json')
      Updater.new(load_config(Pathname.new(path)), options.slice(:dry, :git)).run
    end

    private

    def load_config(config_file)
      return JSON.parse(config_file.read) if config_file.exist?

      Console.logger.info("Couldn\'t find #{config_file} file, falling back to default values")
      DEFAULT_CONFIGURATION
    end
  end
end
