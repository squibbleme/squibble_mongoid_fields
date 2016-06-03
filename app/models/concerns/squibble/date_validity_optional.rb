# Issue #158: Verrechnungstypen für Workshops (DateValidityOptional)
# ==================================================================
#
# Analog zum Squibble::DateValidity Concern werden hier :valid_from
# und :valid_till Attribute hinzugefügt. Diese sind hier aber optional.
#
# Weiter werden diese auf generelle Überlappung validiert. Sollen
# nicht alle Objekte desselben Typs miteinander auf Überlappung verglichen
# werden, so muss die :_date_validity_query_hash Methode überschrieben
# werden. Damit kann die Validierung eingeschränkt werden.
#
# Bsp: Business::TaxAssignment, Business::AccountAssignment,
# Workshop::Clearing::Assignment
#
# Über den folgenden include im Model ist dies möglich:
# [...]
# include Squibble::DateValidityOptional
# [...]
#
module Squibble::DateValidityOptional
  extend ActiveSupport::Concern
  include ApplicationHelper

  included do
    def self.included(_base)
    end

    field :valid_from,
          type: Date

    field :valid_till,
          type: Date

    validate :_validates_valid_from_to_be_smaller_then_valid_till
    validate :_validates_non_overlapping_resources

    # Filtert die aktiven :resources, wobei auf optionale :valid_from
    # und :valid_till geachtet werden muss. Nicht gesetzt, heisst das,
    # sie sind ohne zeitliche Einschränkung gültig.
    #
    # TODO: Sehr unschön, Verbesserungswürdig (if possible)
    # Problem: CanCanCan Ability :principal_id wird im any_of 'OR' Block
    # mitgeführt
    #
    scope :active, -> (valuta = Time.zone.today) do
      class_name = eval(name)
      any_in(
        id: [
          class_name.where(valid_from: nil, valid_till: nil).distinct(:id),
          class_name.where(:valid_from.lte => valuta, valid_till: nil).distinct(:id),
          class_name.where(valid_from: nil, :valid_till.gte => valuta).distinct(:id),
          class_name.where(:valid_from.lte => valuta, :valid_till.gte => valuta).distinct(:id)
        ].flatten
      )
    end

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
        { principal_id: principal_id }
      else
        {}
      end
    end

    # Diese Methode generiert den korrekten Fehler für die Validierung.
    #
    def _handle_error(error_key, from, till)
      model_name = translated_resource_class(self.class)
      translate_error_key = ['concerns.models.squibble.date_validity_optional.period_validation.base', error_key].join('.')

      if error_key == :from_nil_till_nil
        msg = I18n.t(translate_error_key.to_sym, model_name: model_name)
        errors.add :base, msg

      elsif error_key == :from_nil_till_present
        msg = I18n.t(translate_error_key.to_sym, model_name: model_name, till: I18n.l(till))
        errors.add :base, msg

      elsif error_key == :from_present_till_nil
        msg = I18n.t(translate_error_key.to_sym, model_name: model_name, from: I18n.l(from))
        errors.add :base, msg

      elsif error_key == :from_present_till_present
        msg = I18n.t(translate_error_key.to_sym, model_name: model_name, from: I18n.l(from), till: I18n.l(till))

      end

      errors.add :base, msg
    end

    # Validierung, dass pro Objekt mit denselben Zuweisungen keine Duplikate
    # für denselben Zeitraum existieren (keine Überlappungen!).
    #
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

      # Iteriere über alle gefundenen, ähnlichen :affected_objects und prüfe, ob
      # diese nicht mit der zu validierenden :resource überlappen.
      #
      affected_objects.each do |affected_object|
        # Fall 1: Zu vergleichendes :affected_object hat :valid_from und :valid_till nicht
        # gesetzt. Dieses :affected_object ist ohne zeitliche Einschränkung gültig, somit
        # ist die zu validierende :resource in jedem Fall ungültig.
        #
        if affected_object.valid_from.nil? && affected_object.valid_till.nil?
          _handle_error(:from_nil_till_nil, affected_object.valid_from, affected_object.valid_till)

        # Fall 2: Zu vergleichendes :affected_object hat :valid_from nicht gesetzt, dafür
        # ein :valid_till.
        #
        elsif affected_object.valid_from.nil? && affected_object.valid_till.present?
          # Wird ein :affected_object gefunden, welches seine Gültigkeit erst später
          # verliert, als das :valid_from der :resource, so ist die :resource ungültig.
          #
          if valid_from.nil? || affected_object.valid_till >= valid_from
            _handle_error(:from_nil_till_present, affected_object.valid_from, affected_object.valid_till)
          end

        # Fall 3: Zu vergleichendes :affected_object hat :valid_from gesetzt, dafür ist
        # das :valid_till nicht gesetzt.
        #
        elsif affected_object.valid_from.present? && affected_object.valid_till.nil?
          # Wird ein :affected_object gefunden, das seine Gültigkeit beginnt, bevor
          # die zu validierende :resource an ihrem :valid_till endet, so ist die
          # :resource ungültig.
          #
          if valid_till.nil? || affected_object.valid_from <= valid_till
            _handle_error(:from_present_till_nil, affected_object.valid_from, affected_object.valid_till)
          end

        # Fall 4: Zu vergleichendes :affected_object hat sowohl :valid_from, als auch
        # :valid_till gesetzt. (Analog zum 'Normalfall' ohne nil-Werte, wie bei
        # Squibble::DateValidity)
        #
        elsif affected_object.valid_from.present? && affected_object.valid_till.present?
          if valid_from.nil? && valid_till.nil?
            # 4.1: Ist die zu validierende :resource ohne zeitliche Einschränkung gültig,
            # aber es wurde bereits ein :affected_object mit den gleichen Kriterien gefunden,
            # so muss die :resource ungültig sein.
            #
            _handle_error(:from_present_till_present, affected_object.valid_from, affected_object.valid_till)

          elsif valid_from.present? && valid_till.nil?
            # 4.2: :resource ist immer gültig ab :valid_from, überschneidet sich dies mit dem
            # :affected_object, so ist die :resource ungültig.
            #
            if affected_object.valid_till >= valid_from
              _handle_error(:from_present_till_present, affected_object.valid_from, affected_object.valid_till)
            end

          elsif valid_from.nil? && valid_till.present?
            # 4.3: :resource ist immer gültig bis :valid_till, überschneidet sich dies
            # mit dem :affected_object, so ist die :resource ungültig.
            #
            if affected_object.valid_from <= valid_till
              _handle_error(:from_present_till_present, affected_object.valid_from, affected_object.valid_till)
            end

          elsif valid_from.present? && valid_till.present?
            # 4.4: Standardvalidierung à la Squibble::DateValidity
            #
            if affected_object.valid_from <= valid_till && affected_object.valid_till >= valid_from
              _handle_error(:from_present_till_present, affected_object.valid_from, affected_object.valid_till)
            end
          end
        end
      end
    end

    def _validates_valid_from_to_be_smaller_then_valid_till
      return unless valid_from.present?
      return unless valid_till.present?
      return if valid_from < valid_till

      errors.add :valid_from, :valid_from_to_be_smaller_than_valid_till
      errors.add :valid_till, :valid_till_to_be_larger_than_valid_from
    end
  end
end
