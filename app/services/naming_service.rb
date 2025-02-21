class NamingService
  # If filename exists within the directory,
  # return a count based alternative, E.g. filename_copy-01.png, filename_copy-02.png
  # If not, return the original filename.
  #   original_filename: the filename in String
  #   pathname: Pathname object
  def self.name_file(original_filename:, pathname:)
    # Remove newlines and duplicate spaces
    original_filename = original_filename.squish

    return original_filename unless File.exists?(pathname.join(original_filename))

    extension = File.extname(original_filename)
    basename = File.basename(original_filename, extension)
    matching_filenames = Dir.glob(pathname.join("#{basename}_copy-*#{extension}"))

    new_name(
      name: basename,
      sequence: next_sequence(matching_names: matching_filenames, suffix: extension),
      suffix: extension
    )
  end

  # If an project with the name exists,
  # return a count based alternative, E.g. My Project Name_copy-01, My Project Name_copy-02
  # If not, return the name with a count based alternative.
  #   name: the project name
  def self.name_project(name)
    return name unless Project.exists?(name: name)

    projects = Project.where("name REGEXP ?", "^#{name}_copy-[0-9]+$")
    project_names = projects.map(&:name)

    new_name(
      name: name,
      sequence: next_sequence(matching_names: project_names)
    )
  end

  private

  def self.new_name(name:, sequence:, suffix: nil)
    "%s_copy-%02i%s" % [name, sequence, suffix]
  end

  def self.next_sequence(matching_names: [], suffix: nil)
    current_sequence = matching_names.map { |matching_name| matching_name.match(/_copy-([0-9]+)#{suffix}\z/)[1].to_i }.max || 0
    current_sequence + 1
  end
end
