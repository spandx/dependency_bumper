# frozen_string_literal: true

RSpec.describe DependencyBumper::Cli do
  before(:all) do
    @g = Git.open('.')
  end

  it 'loads given configuration' do
    temp_config = { 'skip' => {}, 'outdated_level' => 'strict', 'update' => { 'default' => 'minor', 'major' => {}, 'minor' => {}, 'patch' => {} } }
    config_file_with_defaults = create_temporary_config_file(temp_config)
    arguments = ['bump_gems', '--config', config_file_with_defaults.path]
    allow(DependencyBumper::Updater).to receive(:new).with(temp_config, {}).and_return(double(run: true))
    DependencyBumper::Cli.start(arguments)
    expect(DependencyBumper::Updater).to have_received(:new).with(temp_config, {})
  end

  it 'updates dependencies for given Gemfile' do
    Bundler.reset!
    path = fixture_file('Gemfile')
    lock_file = fixture_file('Gemfile.lock')

    FileUtils.copy_file(lock_file, "#{lock_file}.bak")

    Bundler::SharedHelpers.set_env('BUNDLE_GEMFILE', path.to_s)
    DependencyBumper::Cli.start(['bump_gems'])
    expect(@g.status.changed?('spec/fixtures/Gemfile.lock')).to be(true)

    FileUtils.copy_file("#{lock_file}.bak", lock_file)
    FileUtils.remove("#{lock_file}.bak")
  end
end
