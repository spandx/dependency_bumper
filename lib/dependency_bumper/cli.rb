# frozen_string_literal: true

module DependencyBumper
  class Cli < Thor
    package_name 'Dependency Bumper'

    option :config, type: :string
    option :git, type: :boolean
    desc 'bump_gems', 'update dependencies of your Ruby project'
    long_desc <<-LONGDESC
     `bump_gems` will update dependencies of your Ruby project

    If you give --git option it will create a branch and commit message will include information about updated gems.

    This gem looks for a config file called bumper_config.json by default and if it doesn't find it, it will use default

    configuration. You can point out another folder for configuration.

    > $ dbump bump_gemps --git --config myconfig.json
    LONGDESC

    def bump_gems
      config = if options[:config]
                 load_config(options[:config])
               else
                 load_config
        end

      Updater.new(config).run
    end

    private

    def load_config(config_file = '.bumper_config.json')
      if Pathname.new(config_file).exist?
        contents = File.new(config_file).read
        JSON.parse(contents)
      else
        Console.logger.info("Couldn\'t find #{config_file} file, falling back to default values")

        { 'skip' => {}, 'outdated_level' => 'strict', 'update' => { 'default' => 'minor', 'major' => {}, 'minor' => {}, 'patch' => {} } }
      end
    end
  end
end
