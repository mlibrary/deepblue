# frozen_string_literal: true
# hyrax-orcid

module Hyrax
  module Orcid
    class DatabaseMigrator < Hyrax::DatabaseMigrator
      def self.migrations_dir
        Hyrax::Orcid::Engine.root.join('lib', 'generators', 'hyrax', 'orcid', 'templates')
      end
    end
  end
end
