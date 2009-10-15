require 'rcov/rcovtask'
require 'hanna/rdoctask'

desc 'Run all specs in spec/'
task :spec do
  require 'bacon'
  Bacon.extend Bacon::TestUnitOutput
  Bacon.summary_on_exit

  Dir['spec/**/*.rb'].each {|f| require f}
end

def deploy target
  `rsync -r --exclude=.git* --exclude=vendor/* . #{target}`
end

desc 'Deploy to Dreamhost'
task :deploy do
  deploy 'seanmcgivern@tombstone.org.uk:~/domains/giggregator/'
end
