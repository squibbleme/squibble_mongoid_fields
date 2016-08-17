#
# Über den folgenden include im Model ist dies möglich:
#
# [...]
# include Squibble::Label
# [...]
#
module Squibble::Label
  extend ActiveSupport::Concern

  included do
    field :label, type: String, localize: true
  end
end
