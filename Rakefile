begin
  require 'rcov/rcovtask'

  namespace :spec do
    desc 'Generate C0 code coverage information for specs'
    Rcov::RcovTask.new :cov do |t|
      t.test_files = FileList['spec/**/*_spec.rb']
      t.output_dir = 'tmp/cov'
      t.verbose = true
    end
  end
rescue LoadError
end

desc 'Remove duplicates from the database'
task :remove_duplicates do
  require 'setup'

  Band.all.each do |band|
    band.gigs.each do |gig|
      band.gigs.each do |other|
        other.delete if (other.time == gig.time && other.id < gig.id)
      end
    end
  end
end

desc 'Run all specs in spec/'
task :spec do
  require 'bacon'

  Bacon.extend Bacon::TestUnitOutput
  Bacon.summary_on_exit

  Dir['spec/**/*.rb'].each {|f| require f}
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

desc 'Backup database file'
task :backup_db do
  ['', '-journal'].each do |s|
    if (file = "tmp/giggregator.db#{s}" and File.exist?(file))
      cp(file,
         "tmp/backup-#{Time.now.strftime('%Y%m%d-%H%M')}.db#{s}")
    end
  end
end
