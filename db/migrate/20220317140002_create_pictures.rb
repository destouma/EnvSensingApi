class CreatePictures < ActiveRecord::Migration[6.0]
  def change
    create_table :pictures do |t|
      t.references :sensor, null: false, foreign_key: true
      t.string :file_name
      t.string :file_url
      t.timestamps
    end
  end
end