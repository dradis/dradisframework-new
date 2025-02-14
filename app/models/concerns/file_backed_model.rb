# Parse a note template from ./templates/notes/
#
# See:
#   http://yehudakatz.com/2010/01/10/activemodel-make-any-ruby-object-feel-like-activerecord/
#   http://asciicasts.com/episodes/219-active-model
#   https://github.com/rails/rails/blob/master/activemodel/lib/active_model/conversion.rb
module FileBackedModel
  class FileNotFoundException < Exception; end

  def self.included(base)
    @base = base

    base.extend ClassMethods
    base.class_eval do
      include ActiveModel::Validations
      include ActiveModel::Conversion
      extend ActiveModel::Naming
      include Enumerable

      attr_accessor :content, :filename, :updated_at

      validates_presence_of :name
      validates_format_of :name, with: /\A\w+[\w\s]*\z/, message: 'needs to be simple: please use letters, numbers and spaces'
    end
  end

  module ClassMethods
    # ------------------------------------------------------- Common attributes
    # The default file extension to attach to each saved file.
    def extension
      @extension ||= '.txt'
    end

    def set_extension(new_extension)
      @extension = ".#{new_extension}"
    end

    # Creates an instance of the model from a given file on disk.
    def from_file(filename)
      # raise 'Unimplemented!'
      new({
        filename: File.basename(filename, self.extension),
        content: File.read(filename),
        updated_at: File.mtime(filename)
      })
    end

    def pwd
      @pwd ||= Pathname.new(@default_path)
    end

    def set_pwd(path)
      @default_path = path
    end

    # ---------------------------------------------------- ActiveRecord finders

    # Find by :id, which in this case is the file's basename
    def find(id)
      # Discard any input with weird characters
      if (id =~ /\A[\x00\/\\:\*\?\"<>\|]\z/)
        raise Exception.new('Not found!')
      end

      # Cycle through valid templates looking for a match
      result = nil

      Dir[self.pwd.join("**#{self.extension}")].each do |file|
        next unless File.basename(file, extension) == id
        result = self.from_file(file)
        break
      end

      raise FileNotFoundException.new('Not found!') unless result.present?
      return result
    end

    # Returns a collection of NoteTemplate objects from the currently configured
    # methodologies path. See NoteTemplate.pwd()
    def all()
      Dir[self.pwd.join("**#{self.extension}")].collect do |file|
        self.from_file(file)
      end.sort
    end
  end # /ClassMethods

  # --------------------------------------------------------- ActiveModel::Lint

  # ActiveModel expects you to define an id() method to uniquely identify each
  # model
  def id() persisted? ? self.filename : nil end

  def new_record?()
    # return true unless self.filename
    return !File.exist?(full_path)
  end

  # def destroyed?()  true end
  def persisted?()
    @persisted ||= File.exist?(full_path)
  end

  # ---------------------------------------------------------------- Enumerable

  # When comparing two NoteTemplate instances, sort them alphabetically on their
  # name
  def <=>(other)
    self.name <=> other.name
  end

  # -------------------------------------------------- Constructors & Lifecycle

  # Constructor a la ActiveRecord. Attributes: :name, :file
  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end

  def destroy
    return true unless filename && File.exist?(full_path)
    File.delete(full_path)
    self
  end
  alias :delete :destroy

  def save
    return false if !valid?
    FileUtils.mkdir_p(self.class.pwd) unless File.exist?(self.class.pwd)
    File.open(full_path, 'w') do |f|
      f << self.content
    end
    return true
  end

  # ---------------------------------------------------------------- Attributes
  def filename
    @filename ||= "auto_#{Time.now.to_i}"
  end

  def full_path
    self.class.pwd.join("#{self.filename}#{self.class.extension}")
  end

  # By default the instance name comes from the file name on disk. This can be
  # overriden by the including class to retrieve the name from the file itself
  # like the ProjectTemplate class.
  def name
    filename ? filename.titleize : nil
  end

  def name=(new_name)
    self.filename = new_name.gsub(/ /, '_').underscore
  end
end
