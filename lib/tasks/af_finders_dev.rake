APP_ROOT = File.expand_path("#{File.dirname(__FILE__)}/../../")

namespace :active_fedora_finders do
  require 'active_fedora_finders'

  # Use yard to build docs
  begin
    require 'yard'
    require 'yard/rake/yardoc_task'
    project_root = APP_ROOT
    doc_destination = File.join(project_root, 'doc')

    YARD::Rake::YardocTask.new(:doc) do |yt|
      yt.files   = Dir.glob(File.join(project_root, 'lib', '**', '*.rb')) + 
                   [ File.join(project_root, 'README.textile')]
      yt.options = ['--output-dir', doc_destination, '--readme', 'README.textile']
    end
  rescue LoadError
    desc "Generate YARD Documentation"
    task :doc do
      abort "Please install the YARD gem to generate rdoc."
    end
  end

  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:rspec) do |spec|
    spec.pattern = FileList['spec/**/*_spec.rb']
    spec.pattern += FileList['spec/*_spec.rb']
  end

  RSpec::Core::RakeTask.new(:rcov) do |spec|
    spec.pattern = FileList['spec/**/*_spec.rb']
    spec.pattern += FileList['spec/*_spec.rb']
    spec.rcov = true
  end

end