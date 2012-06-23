require 'active-fedora'
require 'active_support'
require 'active_record'
module ActiveFedora
  module Finders
    extend ActiveSupport::Concern
    extend ActiveSupport::Autoload
    autoload :Version

    SINGLE_VALUE_FIELDS = [:pid, :cDate, :mDate, :label]
    SYSTEM_FIELDS = SINGLE_VALUE_FIELDS.concat [:ownerId]
    DC_FIELDS = [:contributor, :coverage, :creator, :date, :description, :format,
                 :identifier, :language, :publisher, :relation, :rights, :source,
                 :subject, :title, :type ]
    SUPPORTED_ALTS = [:cdate, :create_date, :mdate, :modified_date, :owner_id]
    ALL_FIELDS = SYSTEM_FIELDS.concat(DC_FIELDS)
    FIELD_KEYS = begin
      fk = Hash[ALL_FIELDS.map {|a| [a.to_s, a]}]
      fk["cdate"] = :cDate
      fk["create_date"] = :cDate
      fk["mdate"] = :mDate
      fk["modified_date"] = :mDate
      fk["owner_id"] = :ownerId
      fk
    end

    included do
      class << self
        alias_method :active_fedora_find, :find
      end
    end

    module ClassMethods    
      def find(args)
        if args.is_a? String
          return active_fedora_find(args)
        else
          return find_by_conditions(args)
        end
      end
        
      # modeled after ActiveRecord::FinderMethods.find_by_attributes
      def find_by_attributes(match, attribute_names, *args)
        conditions = Hash[attribute_names.map {|a| [a, args[attribute_names.index(a)]]}]
        result = find_by_conditions(conditions)
        if match.bang? && result.blank?
          raise RecordNotFound, "Couldn't find #{self.name} with #{conditions.to_a.collect {|p| p.join(' = ')}.join(', ')}"
        else
          yield(result) if block_given?
          result
        end
      end
    
      def find_by_conditions(match, args)
        parms = args.dup
        parms[:cDate] = parms.delete(:create_date) if parms[:create_date]
        parms[:cDate] = parms.delete(:cdate) if parms[:cdate]
        parms[:mDate] = parms.delete(:modified_date) if parms[:modified_date]
        parms[:mDate] = parms.delete(:mdate) if parms[:mdate]
        parms[:ownerId] = parms.delete(:owner_id) if parms[:owner_id]
        parms[:identifier] = parms.delete(:id) if parms[:id]
      
        query = ""
        parms.each { |key, val|
          if SINGLE_VALUE_FIELDS.include? key
            query.concat "#{key.to_s}=#{val.to_s} "
          else
            query.concat "#{key.to_s}~#{val.to_s} "
          end
        }
        query.strip!
        results = ""
        if ActiveFedora.config.sharded?
          (0...ActiveFedora.config.credentials.length).each {|ix|
            ActiveFedora::Base.fedora_connection[ix] ||= ActiveFedora::RubydoraConnection.new(ActiveFedora.config.credentials[ix])
            rubydora = ActiveFedora::Base.fedora_connection[ix].connection
            results.concat rubydora.find_objects(:query=>query,:pid=>'true')
          }
        else
          ActiveFedora::Base.fedora_connection[0] ||= ActiveFedora::RubydoraConnection.new(ActiveFedora.config.credentials)
          rubydora = ActiveFedora::Base.fedora_connection[0].connection
          results = rubydora.find_objects(:query=>query,:pid=>'true')
        end
        results = Nokogiri::XML.parse(results)
        results = results.xpath('/f:result/f:resultList/f:objectFields/f:pid',{'f'=>"http://www.fedora.info/definitions/1/0/types/"})
        results.length > 0 ? results.collect { |result| active_fedora_find(result.text) } : active_fedora_find(results[0].text)
      end
      
      # this method is patterned after an analog in ActiveRecord::DynamicMatchers
      def all_attributes_exists?(attribute_names)
        field_keys = attribute_names.map {|val| FIELD_KEYS[val] or val}
        attribute_names.replace field_keys
        attribute_names.reduce(true) {|result, att| ALL_FIELDS.include? att or SUPPORTED_ALTS.include? att}
      end
      
      # adapted from ActiveRecord::DynamicMatchers
      def method_missing(method_id, *arguments, &block)
        if match = (ActiveRecord::DynamicFinderMatch.match(method_id) || ActiveRecord::DynamicScopeMatch.match(method_id))
          attribute_names = match.attribute_names
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