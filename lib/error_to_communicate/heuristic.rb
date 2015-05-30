module ErrorToCommunicate
  class Heuristic
    def self.for?(einfo)
      raise NotImplementedError, "#{self} needs to implement .for? (subclass responsibility)"
    end

    attr_accessor :project
    attr_accessor :classname, :backtrace, :message

    def initialize(attributes)
      self.project   = attributes.fetch(:project)
      self.classname = attributes.fetch(:einfo).classname
      self.backtrace = attributes.fetch(:einfo).backtrace
      self.message   = attributes.fetch(:einfo).message
    end

    # Is this really a thing that should be in toplevel heuristic?
    def explanation
      message
    end

    def semantic_explanation
      explanation
    end

    # The responsibility of structuring should move to the heuristic
    # Then, the classname and explanation can be separated from the
    # summary and columns. Which allows us to compose heuristics
    # by composing their columnal information, and placing it in our own
    # structural format
    def semantic_summary
      [:summary, [
        [:columns,
          [:classname,   classname],
          [:explanation, semantic_explanation]]]]
    end

    def semantic_info
      [:null]
    end

    def semantic_backtrace
      [:backtrace,
        backtrace.map do |location|
          [:code, {
            location:  location,
            highlight: (location.pred && location.pred.label),
            context:   0..0,
            emphasis:  :path,
            mark:      false,
          }]
        end
      ]
    end
  end
end
