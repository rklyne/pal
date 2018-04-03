Sequel.migration do
  up do
    rename_table :help_entries, :tags
  end

  down do
    rename_table :tags, :help_entries
  end
end
