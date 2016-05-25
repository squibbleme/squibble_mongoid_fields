#
# Über den folgenden include im Model ist dies möglich:
#
# [...]
# include Squibble::Sort
# [...]
#
module Squibble::Sort

  extend ActiveSupport::Concern

  included do

    field :sort,
          type: Integer,
          default: 0
    validates :sort,
              presence: true,
              numericality: {
                only_integer: true,
                greater_than_or_equal_to: 0
              }
  end
end
