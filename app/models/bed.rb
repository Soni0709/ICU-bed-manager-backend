class Bed < ApplicationRecord
  # States
  STATES = %w[available occupied maintenance].freeze
  
  # Validations
  validates :bed_number, presence: true, uniqueness: true
  validates :state, inclusion: { in: STATES }
  validates :patient_name, presence: true, if: -> { state == 'occupied' }
  validates :urgency_level, presence: true, if: -> { state == 'occupied' }
  
  # State checks
  def available?
    state == 'available'
  end
  
  def occupied?
    state == 'occupied'
  end
  
  def maintenance?
    state == 'maintenance'
  end
end
