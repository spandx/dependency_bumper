module Bundler
  class CLI::Outdated
    def run
      check_for_deployment_mode!

      Bundler.definition.validate_runtime!
      # this commands gets current gems
      current_specs = Bundler.ui.silence { Bundler.definition.resolve }

      current_dependencies = Bundler.ui.silence do
        Bundler.load.dependencies.map { |dep| [dep.name, dep] }.to_h
      end

      definition = gems.empty? && sources.empty? ? Bundler.definition(true) : Bunder.definition(gems: gems, sources: sources)

      Bundler::CLI::Common.configure_gem_version_promoter(
        Bundler.definition,
        options
      )

      options[:local] ? definition.resolve_with_cache! : definition.resolve_remotely!

      # Loop through the current specs
      gemfile_specs, dependency_specs = current_specs.partition do |spec|
        current_dependencies.key? spec.name
      end

      specs = gemfile_specs + dependency_specs

      specs.sort_by(&:name).each do |current_spec|
        next unless gems.empty? || gems.include?(current_spec.name)

        active_spec = retrieve_active_spec(definition, current_spec)
        next unless active_spec

        next unless filter_options_patch.empty? || update_present_via_semver_portions(current_spec, active_spec, options)

        gem_outdated = Gem::Version.new(active_spec.version) > Gem::Version.new(current_spec.version)
        next unless gem_outdated || (current_spec.git_version != active_spec.git_version)

        dependency = current_dependencies[current_spec.name]

        outdated_gems_list << {
          active_spec: active_spec,
          current_spec: current_spec,
          dependency: dependency
        }
      end

      return [] if outdated_gems_list.empty?

      print_gems(outdated_gems_list)

      outdated_gems_list
    end

    def print_gem(current_spec, active_spec, dependency)
      spec_version = "#{active_spec.version}#{active_spec.git_version}"
      spec_version += " (from #{active_spec.loaded_from})" if Bundler.ui.debug? && active_spec.loaded_from
      current_version = "#{current_spec.version}#{current_spec.git_version}"

      if dependency && dependency.specific?
        dependency_version = %(, requested #{dependency.requirement})
      end

      spec_outdated_info = "#{active_spec.name} (newest #{spec_version}, " \
      "installed #{current_version}#{dependency_version})"

      output_message = spec_outdated_info.to_s

      Bundler.ui.info output_message.rstrip
    end

    def print_gems(gems_list)
      gems_list.each do |gem|
        print_gem(*gem.values_at(:current_spec, :active_spec, :dependency))
      end
    end
  end
end