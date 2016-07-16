# Dieser Concern kümmert sich darum, dass eine Promotion für einen Datensatz korrekt verwaltet werden kann.
# Zudem wird die entsprechende Validierung sichergestellt.
#
module Squibble::PromotionAttributes
  extend ActiveSupport::Concern

  included do

    field :promotion_valid_from,
          type: DateTime
    field :promotion_valid_till,
          type: DateTime

    validate :_validates_promotion_valid_from_to_be_smaller_then_promotion_valid_till

    scope :currently_in_promotion, -> (valuta = Time.zone.now) do
      class_name = eval(name)
      any_in(
        id: [
          class_name.where(:promotion_valid_from.lte => valuta, promotion_valid_till: nil).distinct(:id),
          class_name.where(promotion_valid_from: nil, :promotion_valid_till.gte => valuta).distinct(:id),
          class_name.where(:promotion_valid_from.lte => valuta, :promotion_valid_till.gte => valuta).distinct(:id)
        ].flatten
      )
    end

    private

    def _validates_promotion_valid_from_to_be_smaller_then_promotion_valid_till
      return unless promotion_valid_from.present?
      return unless promotion_valid_till.present?
      return if promotion_valid_from < promotion_valid_till

      errors.add :promotion_valid_from, :promotion_valid_from_to_be_smaller_than_valid_till
      errors.add :promotion_valid_till, :promotion_valid_till_to_be_larger_than_valid_from
    end
  end
end
