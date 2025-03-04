class AddGpxFilesUserIdTimestampIndex < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :gpx_files, [:user_id, :timestamp], algorithm: :concurrently
  end
end 