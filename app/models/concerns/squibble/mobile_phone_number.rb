#
# Über den folgenden include im Model ist dies möglich:
#
# [...]
# include Squibble::MobilePhoneNumber
# [...]
#
module Squibble::MobilePhoneNumber

  extend ActiveSupport::Concern

  included do

    field :mobile_phone_number,
          type: String
    validates :mobile_phone_number,
              allow_blank: true,
              length: {
                maximum: 100
              }
  end
end
