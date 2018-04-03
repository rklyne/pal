Sequel.migration do
  up do
    add_column :feed_posts, :attachment_url, String
  end

  down do
    drop_column :feed_posts, :attachment_url, String
  end
end
