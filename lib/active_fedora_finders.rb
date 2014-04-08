require 'active_fedora'
require 'active_support'
require 'active_support/deprecation'
require 'active_record'
require 'active_record/errors' # RecordNotFound is not autoloaded, and ActiveRecord::Base not referenced
module ActiveFedora::FinderMethods::RepositoryMethods
  autoload :Version, 'active_fedora_finders/version'
  autoload :Relation, 'active_fedora_finders/relation'
  extend ActiveSupport::Concern
  module ClassMethods
    def search_repo(conditions={})
      Relation.new(self).where!(conditions)
    end
  end
end
module ActiveFedora::Finders
  extend ActiveSupport::Concern
  included do
    ActiveSupport::Deprecation.warn("ActiveFedora::Finders will be removed in favor of ActiveFedora::FinderMethods::RepositoryMethods")
    include ActiveFedora::FinderMethods::RepositoryMethods
  end    
end