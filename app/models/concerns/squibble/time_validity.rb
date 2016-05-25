#
# Über den folgenden include im Model ist dies möglich:
#
# [...]
# include Squibble::TimeValidity
# [...]
#
module Squibble::TimeValidity

  extend ActiveSupport::Concern

  included do
    def self.included(base)
    end

    field :valid_from,
          type: DateTime
    validates :valid_from,
              presence: true
    validate :_validates_valid_from_to_be_smaller_then_valid_till

    field :valid_till,
          type: DateTime
    validates :valid_till,
              presence: true

    scope :active, lambda { |valuta = Time.zone.now|
      where(
        :valid_from.lte => valuta,
        :valid_till.gte => valuta
      )
    }

    scope :expires_within_30_days, -> (date = Time.zone.now) { where(:valid_till.lte => (date + 30.days), :valid_till.gte => date) }

    private

    def _validates_valid_from_to_be_smaller_then_valid_till
      return if valid_from < valid_till

      errors.add :valid_from, :valid_from_to_be_smaller_than_valid_till
      errors.add :valid_till, :valid_till_to_be_larger_than_valid_from
    end
  end
end
