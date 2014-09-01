# encoding: UTF-8

module Rosette
  module Serializers

    class Serializer
      attr_reader :stream

      class << self
        def from_stream(stream)
          new(stream)
        end

        def open(file)
          new(File.open(file))
        end
      end

      def write_translation(trans)
        raise NotImplementedError, 'expected to be implemented in child classes'
      end

      def close
        raise NotImplementedError, 'expected to be implemented in child classes'
      end
    end

  end
end
