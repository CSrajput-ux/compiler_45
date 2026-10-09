require_relative 'languages/archived'
require_relative 'languages/active'

ActiveRecord::Base.transaction do
  Language.unscoped.delete_all
  allowed_language_ids = [50, 54, 60, 62, 63, 71, 82]
  @languages.select! { |language| allowed_language_ids.include?(language[:id]) }
  @languages.each_with_index do |language, index|
    Language.create(
      id: language[:id],
      name: language[:name],
      is_archived: language[:is_archived],
      source_file: language[:source_file],
      compile_cmd: language[:compile_cmd],
      run_cmd: language[:run_cmd],
    )
  end
end
