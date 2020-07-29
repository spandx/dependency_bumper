require 'bundler'
require 'bundler/cli'
require 'bundler/cli/outdated'
require 'bundler/cli/update'
require 'thor'
require 'json'
require 'open3'
require 'open3'
require 'etc'
require 'git'
require 'console'
require 'zeitwerk'

core_ext = "#{__dir__}/dependency_bumper/bundler"
loader = Zeitwerk::Loader.for_gem
loader.ignore(core_ext)
loader.setup

module DependencyBumper
end

loader.eager_load