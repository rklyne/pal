Sequel.migration do
  up do
    add_column(:relay_targets, :carrier, String)
  end

  down do
    drop_column(:relay_targets, :carrier)
  end
end
