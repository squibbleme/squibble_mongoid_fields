# Dieses Modul kümmert sich darum, dass die die Firmenadresse
# automatisch vom Mandaten auf diesen Datensatz übertragen wird.
#
# Über den folgenden include im Model ist dies möglich:
#
# [...]
# include Squibble::CompanyAddress
# [...]
#
module Squibble::CompanyAddress

  extend ActiveSupport::Concern

  included do
    def self.included(base)
      base.before_save :_copy_company_address
    end

    embeds_one :company_address,
               class_name: 'Address',
               inverse_of: nil

    private

    def _copy_company_address
      return if record.company_address.present?
      record.company_address = record.principal.address
    end
  end
end
