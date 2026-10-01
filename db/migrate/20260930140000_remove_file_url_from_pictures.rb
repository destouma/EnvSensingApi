class RemoveFileUrlFromPictures < ActiveRecord::Migration[8.1]
  # file_url held the absolute server path of the file; the path is now derived
  # from the stored file name by the uploader.
  def change
    remove_column :pictures, :file_url, :string
  end
end
