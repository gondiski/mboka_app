class CreateDigestSchedules < ActiveRecord::Migration[8.0]
  def change
    create_table :digest_schedules do |t|
      t.integer :days, array: true, default: []
      t.time :send_time, null: false
      t.boolean :active, default: true
      t.timestamps
    end
  end
end
