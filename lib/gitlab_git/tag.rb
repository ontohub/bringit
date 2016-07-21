module Gitlab
  module Git
    class Tag < Ref
      attr_reader :object_sha

      def initialize(repository, object, name, target, message = nil)
        super(repository, name, target)
        @object_sha = if object.respond_to?(:oid)
                        object.oid
                      elsif object.respond_to?(:name)
                        object.name
                      elsif object.is_a? String
                        object
                      else
                        nil
                      end
        @message = message
      end

      def message
        encode! @message
      end
    end
  end
end
