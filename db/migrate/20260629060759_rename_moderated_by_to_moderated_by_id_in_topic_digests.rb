class RenameModeratedByToModeratedByIdInTopicDigests < ActiveRecord::Migration[8.0]
  def change
    rename_column :topic_digests, :moderated_by, :moderated_by_id
  end
end
