#
# Über den folgenden include im Model ist dies möglich:
#
# [...]
# include Squibble::BankInformation
# [...]
#
module Squibble::BankInformation

  extend ActiveSupport::Concern

  included do

    field :bank_name,
          type: String

    field :bank_account_number,
          type: String

    field :bank_bic,
          type: String

    field :bank_clearing_number,
          type: String

    field :bank_iban_number,
          type: String
  end
end
