#
# Über den folgenden include im Model ist dies möglich:
#
# [...]
# include Squibble::Email
# [...]
#
module Squibble::Email
  extend ActiveSupport::Concern

  included do
    field :email,
          type: String
    validates :email,
              email: true,
              allow_blank: true,
              allow_nil: true
  end
end
