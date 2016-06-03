#
# Über den folgenden include im Model ist dies möglich:
#
# [...]
# include Squibble::Quantity
# [...]
#
module Squibble::Quantity
  extend ActiveSupport::Concern

  included do
    field :quantity,
          type: Float,
          default: 1.0
    validates :quantity,
              presence: true,
              numericality: {
                only_integer: false
              }
  end
end
