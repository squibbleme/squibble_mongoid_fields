#
# Über den folgenden include im Model ist dies möglich:
#
# [...]
# include Squibble::Discount
# [...]
#
module Squibble::Discount
  extend ActiveSupport::Concern

  included do
    field :discount,
          type: Float,
          default: 0.0
    validates :discount,
              presence: true,
              numericality: {
                only_integer: false,
                greater_than_or_equal_to: 0.0,
                less_than_or_equal_to: 100.0
              }

    def has_discount?
      discount != 0.0
    end
  end
end
