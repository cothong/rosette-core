# encoding: UTF-8

module Rosette
  module DataStores

    # Contains several constants indicating the translation status of a set
    # of phrases. Generally attached to commit logs.
    module PhraseStatus
      # Indicates the phrases have been imported but not submitted for
      # translation.
      UNTRANSLATED = 'UNTRANSLATED'

      # Indicates the phrases have been submitted for translation.
      PENDING = 'PENDING'

      # Indicates the phrases have been pulled at least once, but not all
      # translations were included.
      PULLING = 'PULLING'

      # Indicates all translations have been downloaded and catalogued.
      PULLED = 'PULLED'

      # Indicates the phrases have all been translated into every supported
      # locale.
      TRANSLATED = 'TRANSLATED'

      # Indicates that the commit no longer exists, i.e. the associated branch
      # was deleted or was force-pushed over.
      MISSING = 'MISSING'

      # Indicates one or all of the commits have not been detected or processed.
      NOT_FOUND = 'NOT_FOUND'

      def self.all
        @all ||= [
          UNTRANSLATED, PENDING, PULLING, PULLED, TRANSLATED, MISSING
        ]
      end

      def self.statuses
        @statuses ||= [
          UNTRANSLATED, PENDING, PULLING, PULLED, TRANSLATED
        ]
      end

      def self.incomplete
        @incomplete ||= [
          UNTRANSLATED, PENDING, PULLING, PULLED
        ]
      end

      def self.index(status)
        (@status_index ||= {}).fetch(status) do
          statuses.index(status)
        end
      end
    end

  end
end
