#
# Über den folgenden include im Model ist dies möglich:
#
# [...]
# include Squibble::DescriptionShort
# [...]
#
module Squibble::DescriptionShort
  extend ActiveSupport::Concern

  included do
    field :description_short, type: String, localize: true
    validates :description_short, allow_blank: true, length: { maximum: 1_500 }
  end
end
