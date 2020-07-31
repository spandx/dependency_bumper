# frozen_string_literal: true

RSpec.describe DependencyBumper do
  let(:default_config) do
    { 'skip' => {}, 'outdated_level' => 'strict', 'update' => { 'default' => 'minor', 'major' => {}, 'minor' => {}, 'patch' => {} } }
  end

  let(:number_of_cores) { Etc.nprocessors }
  let(:wait_thr) { double }
  let(:wait_thr_value) { double }
  let(:stdout) { double }
  let(:stdout) { IOMock.new }

  before do
    outdated_gems_list = [{
      active_spec: nil,
      current_spec: Bundler::EndpointSpecification.new('zeitwerk', '2.3.1', 'ruby', []),
      dependency: nil,
    },
                          {
                            active_spec: nil,
                            current_spec: Bundler::EndpointSpecification.new('console', '1.0.2', 'ruby', []),
                            dependency: nil,
                          }, {
                            active_spec: nil,
                            current_spec: Bundler::EndpointSpecification.new('async', '1.26.1', 'ruby', []),
                            dependency: nil,
                          }]

    allow_any_instance_of(Bundler::CLI::Outdated).to receive(:run).and_return(outdated_gems_list)
  end

  it 'runs with default configuration' do
    allow(Bundler::CLI::Update).to receive(:new).with({ 'jobs' => number_of_cores, 'minor' => true }, ['zeitwerk', 'console', 'async']).and_return(double(run: true))

    DependencyBumper::Updater.new(default_config).run
    expect(Bundler::CLI::Update).to have_received(:new).with({ 'jobs' => number_of_cores, 'minor' => true }, ['zeitwerk', 'console', 'async'])
  end

  it 'reports which gems are updated with patch level' do
    output = "parslet From 1.8.2 To 1.8.3 update level: patch \nthor From 0.20.3 To 1.0.0 update level: major \nzeitwerk From 2.3.0 To 2.4.0 update level: patch \n"

    allow(Bundler::CLI::Update).to receive(:new).with(any_args).and_return(double(run: true))
    instance = DependencyBumper::Updater.new(default_config)
    allow(instance).to receive(:current_gem_file).and_return(fixture_file('before_update.lock'), fixture_file('after_update.lock'))

    instance.run

    expect(instance.report).to include(output)
  end

  it 'skips given dependency' do
    default_config['skip'] = { 'console' => '' }
    allow(Bundler::CLI::Update).to receive(:new).with({ 'jobs' => number_of_cores, 'minor' => true }, ['zeitwerk', 'async']).and_return(double(run: true))

    DependencyBumper::Updater.new(default_config).run

    expect(Bundler::CLI::Update).to have_received(:new).with({ 'jobs' => number_of_cores, 'minor' => true }, ['zeitwerk', 'async'])
  end

  it 'updates given gem with given patch level' do
    default_config['update']['major'] = { 'console' => '' }
    allow(Bundler::CLI::Update).to receive(:new).with({ 'jobs' => number_of_cores, 'major' => true }, ['console']).and_return(double(run: true))
    allow(Bundler::CLI::Update).to receive(:new).with({ 'jobs' => number_of_cores, 'minor' => true }, ['zeitwerk', 'async']).and_return(double(run: true))

    DependencyBumper::Updater.new(default_config).run
    expect(Bundler::CLI::Update).to have_received(:new).with({ 'jobs' => number_of_cores, 'minor' => true }, ['zeitwerk', 'async'])
    expect(Bundler::CLI::Update).to have_received(:new).with({ 'jobs' => number_of_cores, 'major' => true }, ['console'])
  end

  describe 'with git' do
    before do
      allow(wait_thr).to receive(:value).and_return(wait_thr_value)
      allow(wait_thr_value).to receive(:exitcode).and_return(0)
      allow(wait_thr_value).to receive(:success?).and_return(true)
    end

    it 'creates new branch with commit' do
      branch_name = "gem-bump-#{Time.now.strftime('%d-%m-%Y')}"

      updated_gems = <<~END
        addressable From 2.7.0 To 2.8.0
        ast From 2.4.1 To 2.9.1
        benchmark-ips From 2.8.2 To 2.9.2
        benchmark-malloc From 0.2.0 To 0.3.0
      END

      commit_message = <<~END
        Updating gems #{Time.now.strftime('%d-%m-%Y')}
        #{updated_gems}
      END

      Dir.mktmpdir do |dir|
        g = Git.init(dir)

        file = File.new("#{dir}/temp", 'w')
        file.write('hello world')

        dp = DependencyBumper::Updater.new(default_config, true)
        allow(dp).to receive(:report_result).and_return(updated_gems)

        allow(Open3).to receive(:popen3).with('git', 'rev-parse', '--show-toplevel').and_yield(nil, Helpers::IOMock.new([dir]), [], wait_thr)

        dp.run

        expect(g.branches[branch_name]).to be_a(Git::Branch)
        expect(g.log.first.message.strip).to eq(commit_message.strip)
      end
    end
  end
end
