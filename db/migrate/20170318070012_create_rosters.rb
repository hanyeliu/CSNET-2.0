class CreateRosters < ActiveRecord::Migration[5.0]
  def change
    create_table :rosters do |t|
      t.integer :course_num
      t.string :attachment

      t.timestamps
    end
  end
end
