require 'active_record/errors'
module ActiveFedora::FinderMethods::RepositoryMethods
  class Relation

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

    attr_reader :loaded
    attr_accessor :default_scoped
    alias :loaded? :loaded

    def initialize(klass, values = nil)
      @klass = klass
      @loaded = false
      @values = values || {}
    end

    def reset
      spawn.reset!
    end

    def reset!
      @values.delete_if {|k,v| true}
      @loaded = false
      @records = nil
      self
    end

    def spawn
      self.class.new(@klass, @values.dup)
    end

    def where(conditions={})
      spawn.where!(conditions)
    end

    def where!(conditions={})
      query = (@values[:query] ||= {})
      conditions.each do |k,v|
        k = FIELD_KEYS[k.to_s]
        v = Array(v)
        if query[k] and not SINGLE_VALUE_FIELDS.include?(k)
          query[k] = (Array(query[k]) + v).uniq
        else
          query[k] = v[1] ? v : v.first
        end
      end
      self
    end

    def limit(limit_value)
      spawn.limit!(limit_value)
    end

    def limit!(limit_value)
      @values[:maxResults] = limit_value
      self
    end

    def to_a
      load
      @records
    end

    def load
      @records = fcrepo_find(@values)
      @loaded = true
    end

    def first
      if loaded?
        @records.first
      else
        @first ||= limit(1).to_a[0]
      end
    end

    def first!
      r = first()
      raise ActiveRecord::RecordNotFound.new(@values.inspect) unless r
      r
    end

    def find_by(conditions={})
      where(conditions).to_a.first
    end

    def find_by!(conditions={})
      r = find_by(conditions)
      raise ActiveRecord::RecordNotFound.new(conditions.inspect) unless r
      r
    end

    private
    def fcrepo_find(args)
      parms = args.dup
      parms[:query] ||= {}
      if parms[:query][:pid] and parms[:query].size == 1
        return [@klass.find(parms[:query][:pid], cast: false)]
      end
      maxResults = parms[:maxResults] || 25 # find_all and find_last not yet supported    
      
      query = ""
      parms.fetch(:query, {}).each { |key, val|
        if SINGLE_VALUE_FIELDS.include? key
          query.concat "#{key.to_s}=#{val.to_s} "
        else
          Array(val).each do |v|
            query.concat "#{key.to_s}~#{v.to_s} "
          end
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
      return results
    end

    def process_results(results)
      results = Nokogiri::XML.parse(results)
      results = results.xpath('/f:result/f:resultList/f:objectFields/f:pid',{'f'=>"http://www.fedora.info/definitions/1/0/types/"})
      results.collect { |result| @klass.find(result.text, cast: false) }
    end

  end
end	