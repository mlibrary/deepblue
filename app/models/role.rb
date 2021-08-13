# frozen_string_literal: true

# Class modeling Roles within the application
class Role < ActiveRecord::Base
  has_and_belongs_to_many :users

  validates :name,
            uniqueness: true,
            format: {
              with: /\A[a-zA-Z0-9._-]+\z/,
              message: 'Only letters, numbers, hyphens, ' \
              'underscores and periods are allowed'
            }
end
