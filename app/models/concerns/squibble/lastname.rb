module Squibble::Lastname
  extend ActiveSupport::Concern

  included do
    field :lastname,
          type: String
    validates :lastname,
              allow_blank: true,
              allow_nil: true,
              length: {
                maximum: 200
              }
  end
end
