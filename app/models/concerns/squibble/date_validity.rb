#
# Über den folgenden include im Model ist dies möglich:
#
# [...]
# include Squibble::DateValidity
# [...]
#
module Squibble::DateValidity
  extend ActiveSupport::Concern
  include ApplicationHelper

  included do
    def self.included(_base)
    end

    field :valid_from,
          type: Date
    validates :valid_from,
              presence: true

    field :valid_till,
          type: Date
    validates :valid_till,
              presence: true

    validate :_validates_valid_from_to_be_smaller_then_valid_till
    validate :_validates_non_overlapping_resources

    scope :active, lambda { |valuta = Time.zone.today|
      where(
        :valid_from.lte => valuta,
        :valid_till.gte => valuta
      )
    }

    scope :expires_within_30_days, -> (date = Time.zone.today) { where(:valid_till.lte => (date + 30.days), :valid_till.gte => date) }

    private

    # Retourniert einen Hash mit den nötigen Einschränkungen, um potentielle
    # Duplikate zu finden. Standardmässig werden nur Objekte vom selben
    # Mandanten verglichen, oder - wenn nicht verbunden - alle Objekte von
    # demselben Typ.
    #
    # !!! WICHTIG: Diese Methode muss überschrieben werden, wenn die zu
    # vergleichenen Objekte eingeschränkt werden müssen.
    # Dabei wird ein Vergleich mit sich selbst innerhalb der Validierung
    # ausgeschlossen, weshalb .where(:id.ne => id) hier nicht nötig ist.
    #
    # Wird die Methode überschrieben und nil retoruniert, so wird KEINE
    # Überlappungsvalidierung ausgeführt.
    #
    def _date_validity_query_hash
      if respond_to?(:principal_id)
        {
          principal_id: principal_id
        }
      else
        {}
      end
    end

    # Diese Methode generiert den korrekten Fehler für die Validierung.
    #
    def _handle_error(error_key, from, till)
      model_name = translated_resource_class(self.class)
      translate_error_key = ['concerns.models.squibble.date_validity.period_validation.base', error_key].join('.')

      msg = I18n.t(translate_error_key.to_sym, model_name: model_name, from: I18n.l(from), till: I18n.l(till))

      errors.add :base, msg
    end

    def _validates_valid_from_to_be_smaller_then_valid_till
      return if valid_from < valid_till

      errors.add :valid_from, :valid_from_to_be_smaller_than_valid_till
      errors.add :valid_till, :valid_till_to_be_larger_than_valid_from
    end

    def _validates_non_overlapping_resources
      # Wird die Methode überschrieben und nil retoruniert, so wird KEINE
      # Überlappungsvalidierung ausgeführt.
      #
      return if _date_validity_query_hash.nil?

      # Sammeln der :affected_objects, welche dieselben Zuweisungen verbunden haben.
      #
      # TODO: Genauere Einschränkung, um nur diejenigen zu erhallten, welche im
      # in der :resource gefragten Zeitraum zu erhalten. (:active_during(from,till)..)
      #
      affected_objects = self.class.where(_date_validity_query_hash)
                             .where(:id.ne => id)

      # Gibt es keine :affected_objects mit denselben Zuweisungen, so
      # soll dies ein valider Datensatz sein. Gibt es aber :affected_objects,
      # so muss genauer validiert werden.
      #
      return unless affected_objects.exists?

      affected_objects.each do |affected_object|
        if affected_object.valid_from <= valid_till && affected_object.valid_till >= valid_from
          _handle_error(:from_present_till_present, affected_object.valid_from, affected_object.valid_till)
        end
      end
    end
  end
end
