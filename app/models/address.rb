# Repräsentation eines globalen Adress Objektes
#
class Address
  include Mongoid::Document
  include Mongoid::Timestamps
  # include Mongoid::Paranoia
  #
  include SearchableModel

  # settings do
  #   mappings do
  #     indexes :firstname, type: 'string'
  #     indexes :lastname, type: 'string'
  #     indexes :salutation, type: 'string'
  #     indexes :company_name, type: 'string'
  #     indexes :coordinates, type: 'geo_point'
  #   end
  # end

  field :salutation,
        type: String

  field :firstname,
        type: String
  # validates :firstname,
  #   presence: true

  field :lastname,
        type: String
  # validates :lastname,
  #   presence: true

  # Issue 79: Optionales Feld für den
  # Namen der Location, z.B. Hallenstadion
  #
  field :location_name,
        type: String

  # Issue #80: Meta-Tags 'Longitude, Latitude'
  #
  field :latitude,
        type: Float

  field :longitude,
        type: Float

  field :company_name,
        type: String

  field :street,
        type: String
  validates :street,
            presence: true

  # Issue 156: Erweiterung um zusätzliches
  # Feld für die Darstellung der Zusatz Informationen
  # nach der Strasse. Bspw. Postfach
  #
  field :additional_street_information,
        type: String

  field :zip_code,
        type: String
  validates :zip_code,
            presence: true

  field :town,
        type: String
  validates :town,
            presence: true

  # gem 'countries' stellt diverse Methoden
  # zur Verfügung (.is_eu?)
  #
  field :country,
        type: Country

  field :province,
        type: String

  field :district,
        type: String

  field :full_address,
        type: String

  field :state,
        type: String

  # TODO: Handhabung Firstname/Lastname oder CompanyName
  #
  # validate :_presence_of_firstname_and_lastname_or_company_name

  # To String Method
  def to_s
    "#{name}, #{address}"
  end

  def coordinates
    return unless coordinates?
    [ latitude, longitude ]
  end

  def coordinates?
    !(latitude.nil? || longitude.nil?)
  end

  # Retourniert den Namen der Adresse als Kombination aus Vor- und Nachnamen als String
  #
  def name
    if is_company_address?
      company_name
    else
      "#{firstname} #{lastname}"
    end
  end

  # Diese Methode retourniert, ob ein Name für diese
  # Adresse vorhanden ist.
  #
  def name?
    !name.empty?
  end

  # Retourniert die Adresse der aktuellen Adresse als String
  #
  def address
    if country
      "#{street}, #{zip_code} #{town} (#{country})"
    else
      "#{street}, #{zip_code} #{town}"
    end
  end

  def is_company_address?
    company_name.present? && !(firstname.present? && lastname.present?)
  end

  private

  # TODO: Übersetzungen!
  def _presence_of_firstname_and_lastname_or_company_name
    if firstname.nil? && lastname.nil? && company_name.nil?
      errors.add :firstname, :one_is_required
      errors.add :lastname, :one_is_required
      errors.add :company_name, :one_is_required
    end

    if company_name.present? && (firstname.present? || lastname.present?)
      errors.add :firstname, :company_name_is_set_so_first_and_lastname_are_not_allowed
      errors.add :lastname, :company_name_is_set_so_first_and_lastname_are_not_allowed
    end
  end
end
