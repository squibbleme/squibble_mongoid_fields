class KeyValue
  include Mongoid::Document

  field :key,
        type: String,
        localize: true
  validates :key,
            allow_blank: true,
            length: {
              maximum: 200
            }

  field :sort,
        type: Integer,
        default: 0

  field :value,
        type: String,
        localize: true

  def to_s
    key
  end
end
