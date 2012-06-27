require 'active-fedora'
require 'active_support'
require 'active_record'
require 'active_record/errors' # RecordNotFound is not autoloaded, and ActiveRecord::Base not referenced
module ActiveFedora
  module Finders
    extend ActiveSupport::Concern
    extend ActiveSupport::Autoload
    autoload :Version

    SINGLE_VALUE_FIELDS = [:pid, :cDate, :mDate, :label]
    SYSTEM_FIELDS = [:ownerId].concat(SINGLE_VALUE_FIELDS)
    DC_FIELDS = [:contributor, :coverage, :creator, :date, :description, :format,
                 :identifier, :language, :publisher, :relation, :rights, :source,
                 :subject, :title, :type ]
    SUPPORTED_ALTS = [:cdate, :create_date, :mdate, :modified_date, :owner_id]
    ALL_FIELDS = [].concat(SYSTEM_FIELDS).concat(DC_FIELDS)
    FIELD_KEYS = begin
      fk = Hash[ALL_FIELDS.map {|a| [a.to_s, a]}]
      fk["cdate"] = :cDate
      fk["create_date"] = :cDate
      fk["mdate"] = :mDate
      fk["modified_date"] = :mDate
      fk["owner_id"] = :ownerId
      fk
    end

    module ClassMethods    
        
      # modeled after ActiveRecord::FinderMethods.find_by_attributes
      def find_by_attributes(match, attribute_names, *args)
        conditions = Hash[attribute_names.map {|a| [a, args[attribute_names.index(a)]]}]
        result = fcrepo_find(match, conditions)
        if match.bang? && result.blank?
          raise ActiveRecord::RecordNotFound, "Couldn't find #{self.name} with #{conditions.to_a.collect {|p| p.join(' = ')}.join(', ')}"
        else
          yield(result) if block_given?
          result
        end
      end
    
      def fcrepo_find(match, args)
        parms = args.dup
        maxResults = (match.nil? or match.finder == :first) ? 1 : 25 # find_all and find_last not yet supported    
        query = ""
        parms.each { |key, val|
          if SINGLE_VALUE_FIELDS.include? key
            query.concat "#{key.to_s}=#{val.to_s} "
          else
            query.concat "#{key.to_s}~#{val.to_s} "
          end
        }
        query.strip!
        results = []
        if ActiveFedora.config.sharded?
          (0...ActiveFedora.config.credentials.length).each {|ix|
            ActiveFedora::Base.fedora_connection[ix] ||= ActiveFedora::RubydoraConnection.new(ActiveFedora.config.credentials[ix])
            rubydora = ActiveFedora::Base.fedora_connection[ix].connection
            if results.length <= maxResults
              results.concat process_results(rubydora.find_objects(:query=>query,:pid=>'true', :maxResults=>maxResults))
            end
          }
        else
          ActiveFedora::Base.fedora_connection[0] ||= ActiveFedora::RubydoraConnection.new(ActiveFedora.config.credentials)
          rubydora = ActiveFedora::Base.fedora_connection[0].connection
          results.concat process_results(rubydora.find_objects(:query=>query,:pid=>'true', :maxResults=>maxResults))
        end
        return (maxResults == 1) ? results[0] : results
      end
      
      def process_results(results)
        results = Nokogiri::XML.parse(results)
        results = results.xpath('/f:result/f:resultList/f:objectFields/f:pid',{'f'=>"http://www.fedora.info/definitions/1/0/types/"})
        results.collect { |result| find_one(result.text) }
      end
      
      # this method is patterned after an analog in ActiveRecord::DynamicMatchers
      def all_attributes_exists?(attribute_names)
        attribute_names.reduce(true) {|result, att| ALL_FIELDS.include? att or SUPPORTED_ALTS.include? att}
      end
      
      def normalize_attribute_names!(attribute_names)
        field_keys = attribute_names.map {|val| FIELD_KEYS[val] or val}
        attribute_names.replace field_keys
      end
      
      # adapted from ActiveRecord::DynamicMatchers
      def method_missing(method_id, *arguments, &block)
        if match = (ActiveRecord::DynamicFinderMatch.match(method_id) || ActiveRecord::DynamicScopeMatch.match(method_id))
          attribute_names = match.attribute_names
          normalize_attribute_names!(attribute_names)
          super unless all_attributes_exists?(attribute_names)
          if !(match.is_a?(ActiveRecord::DynamicFinderMatch) && match.instantiator? && arguments.first.is_a?(Hash)) && arguments.size < attribute_names.size
            method_trace = "#{__FILE__}:#{__LINE__}:in `#{method_id}'"
            backtrace = [method_trace] + caller
            raise ArgumentError, "wrong number of arguments (#{arguments.size} for #{attribute_names.size})", backtrace
          end
          if match.respond_to?(:scope?) && match.scope?
            self.class_eval <<-METHOD, __FILE__, __LINE__ + 1
              def self.#{method_id}(*args)                                    # def self.scoped_by_user_name_and_password(*args)
                attributes = Hash[[:#{attribute_names.join(',:')}].zip(args)] #   attributes = Hash[[:user_name, :password].zip(args)]
                                                                              #
                scoped(:conditions => attributes)                             #   scoped(:conditions => attributes)
              end                                                             # end
            METHOD
            send(method_id, *arguments)
          elsif match.finder?
            find_by_attributes(match, attribute_names, *arguments, &block)
          elsif match.instantiator?
            find_or_instantiator_by_attributes(match, attribute_names, *arguments, &block)
          end
        else
          super
        end
      end
      
    end
  end
end