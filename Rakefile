require 'rake/clean'
require 'rubygems'
require 'bundler'
require "bundler/setup"
require "active-fedora"
require "active_fedora_finders"

Bundler::GemHelper.install_tasks

# load rake tasks defined in lib/tasks that are not loaded in lib/active_fedora.rb
load "lib/tasks/af_finders_dev.rake" if defined?(Rake)

CLEAN.include %w[**/.DS_Store tmp *.log *.orig *.tmp **/*~]

task :spec => ['active_fedora_finders:rspec']
task :rcov => ['active_fedora_finders:rcov']


task :default => [:spec]