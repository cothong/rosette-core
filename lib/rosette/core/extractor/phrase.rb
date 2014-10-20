# encoding: UTF-8

module Rosette
  module Core

    class Phrase
      include PhraseIndexPolicy
      include PhraseToHash

      attr_reader :key, :meta_key
      attr_accessor :file, :commit_id

      def initialize(key, meta_key = nil, file = nil, commit_id = nil)
        @key = key
        @meta_key = meta_key
        @file = file
        @commit_id = commit_id
      end

      def self.from_h(hash)
        if hash
          new(
            hash[:key], hash[:meta_key],
            hash[:file], hash[:commit_id]
          )
        end
      end
    end

  end
end
