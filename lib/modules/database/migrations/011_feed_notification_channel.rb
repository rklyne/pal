Sequel.migration do
  up do
    add_column :feeds, :notification_channel_id, Integer
  end

  down do
    drop_column :feeds, :notification_channel_id, Integer
  end
end
