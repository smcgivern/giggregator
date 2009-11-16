require 'rcov/rcovtask'

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

def deploy(target, exclude=nil)
  exclude ||= [
               '.git', '.gitignore', 'vendor/*', 'spec', 'tmp/*.db',
               'tmp/feed/*', 'tmp/cov', 'tmp/flog',
              ]

  p `rsync -r --exclude=#{exclude.join(" --exclude=")} . #{target}`
end

desc 'Deploy to Dreamhost'
task :deploy do
  deploy('seanmcgivern@tombstone.org.uk:~/domains/giggregator/')
end

def flog file, source=nil, dir='tmp/flog'
  source ||= [file]
  mkdir dir unless File.exist? dir

  `find #{source.join ' '} -name \\*.rb | xargs flog > #{dir}/#{file}`
  puts "Flog output available at #{dir}/#{file}"
end

desc 'Flog all code in lib/ and spec/, output in tmp/flog/'
task :flog do
  flog 'all', ['lib', 'spec']
end

namespace :flog do
  desc 'Flog all code in lib/'
  task :lib do
    flog 'lib'
  end

  desc 'Flog all code in spec/'
  task :spec do
    flog 'spec'
  end
end

desc 'Remove flog output'
task :clobber_flog do
  rm_r 'tmp/flog'
end
