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

  # Actions with locking
  def assign_patient!(name, urgency)
    transaction do
      lock!                    # Pessimistic lock: SELECT FOR UPDATE
      
      raise "Bed not available" unless available?
      
      update!(
        state: 'occupied',
        patient_name: name,
        urgency_level: urgency,
        assigned_at: Time.current
      )
    end
  end
  
  def discharge_patient!
    transaction do
      lock!
      
      raise "No patient to discharge" unless occupied?
      
      update!(
        state: 'maintenance',
        discharged_at: Time.current
      )
    end
  end
  
  def mark_cleaned!
    transaction do
      lock!
      
      raise "Bed not in maintenance" unless maintenance?
      
      update!(
        state: 'available',
        patient_name: nil,
        urgency_level: nil,
        assigned_at: nil,
        discharged_at: nil
      )
    end
  end

end
