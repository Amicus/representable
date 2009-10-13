require 'spec/rake/spectask'
desc "Run specs"
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec' << 'examples'
  spec.spec_opts = ['--options', "spec/spec.opts"]
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

desc "Run specs with rcov"
Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end
