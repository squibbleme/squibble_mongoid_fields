#
# Über den folgenden include im Model ist dies möglich:
#
# [...]
# include Squibble::Description
# [...]
#
module Squibble::Description
  extend ActiveSupport::Concern

  included do
    field :description, type: String, localize: true
  end
end
