# copied directly from active-fedora
def mock_yaml(hash, path)
  mock_file = mock(path.split("/")[-1])
  File.stubs(:exist?).with(path).returns(true)
  File.expects(:open).with(path).returns(mock_file)
  YAML.expects(:load).returns(hash)
end

def default_predicate_mapping_file
  File.expand_path(File.join(File.dirname(__FILE__),"..","config","predicate_mappings.yml"))
end

def stub_rails(opts={})
  Object.const_set("Rails",Class)
  Rails.send(:undef_method,:env) if Rails.respond_to?(:env)
  Rails.send(:undef_method,:root) if Rails.respond_to?(:root)
  opts.each { |k,v| Rails.send(:define_method,k){ return v } }
end

def unstub_rails
  Object.send(:remove_const,:Rails) if defined?(Rails)
end
    
def setup_pretest_env
  ENV['RAILS_ENV']='test'
  ENV['environment']='test'
end