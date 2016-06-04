module Squibble::Firstname
  extend ActiveSupport::Concern

  included do
    field :firstname,
          type: String
    validates :firstname,
              allow_blank: true,
              allow_nil: true,
              length: {
                maximum: 200
              }
  end
end
