#
# Über den folgenden include im Model ist dies möglich:
#
# [...]
# include Squibble::PhoneNumber
# [...]
#
module Squibble::PhoneNumber

  extend ActiveSupport::Concern

  included do

    field :phone_number,
          type: String
    validates :phone_number,
              allow_blank: true,
              length: {
                maximum: 100
              }
  end
end
