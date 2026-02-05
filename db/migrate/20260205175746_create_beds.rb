class CreateBeds < ActiveRecord::Migration[8.1]
  def change
    create_table :beds do |t|
      t.string :bed_number, null: false
      t.string :state, null: false, default: 'available'
      t.string :patient_name
      t.string :urgency_level
      t.datetime :assigned_at
      t.datetime :discharged_at

      t.timestamps
    end
    add_index :beds, :bed_number, unique: true
    add_index :beds, :state
  end
end
