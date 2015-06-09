
require 'rspec/core/rake_task'
task :default => :spec

desc 'Run specs'
task :spec => ['spec:no_dsl', 'spec:dsl']

namespace :spec do
  desc 'Run specs without DSL'
  RSpec::Core::RakeTask.new(:no_dsl) do |t|
    t.rspec_opts = '-t ~dsl'
  end

  desc 'Run specs with DSL'
  RSpec::Core::RakeTask.new(:dsl) do |t|
  end
end
