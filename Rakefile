require 'rcov/rcovtask'
require 'hanna/rdoctask'

desc 'Run all specs in spec/'
task :spec do
  require 'bacon'

  Bacon.extend Bacon::TestUnitOutput
  Bacon.summary_on_exit

  Dir['spec/**/*.rb'].each {|f| require f}
end

namespace :spec do
  desc 'Generate C0 code coverage information for specs'
  Rcov::RcovTask.new :cov do |t|
    t.test_files = FileList['spec/**/*_spec.rb']
    t.output_dir = 'tmp/cov'
    t.verbose = true
  end
end

def deploy(target, exclude=['git*', 'vendor/*', '*.db'])
  `rsync -r --exclude=#{exclude.join(" --exclude=")} . #{target}`
end

desc 'Deploy to Dreamhost'
task :deploy do
  deploy('seanmcgivern@tombstone.org.uk:~/domains/giggregator/')
end
