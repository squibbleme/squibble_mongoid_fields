#
# Über den folgenden include im Model ist dies möglich:
#
# [...]
# include Squibble::InternalDescription
# [...]
#
module Squibble::InternalDescription

  extend ActiveSupport::Concern

  included do

    # Ablage der Internen Bemerkung
    #
    field :internal_description,
          type: String,
          localize: true
  end
end
