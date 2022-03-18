class AddColumnToPicture < ActiveRecord::Migration[6.0]
  def change
    add_column :pictures, :date_time, :datetime
  end
end
