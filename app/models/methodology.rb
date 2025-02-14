# Parse a Dradis template and convert into a ProjectTemplate object for easy
# access to the templates's meta data such as name, author, etc.
#
# See:
#   http://yehudakatz.com/2010/01/10/activemodel-make-any-ruby-object-feel-like-activerecord/
#   http://asciicasts.com/episodes/219-active-model
#   https://github.com/rails/rails/blob/master/activemodel/lib/active_model/conversion.rb

class Task
  def initialize(xml_node); @node = xml_node; end
  def name(); @node.text(); end
  def checked?(); !!@node['checked']; end
end

class Section
  def initialize(xml_node); @node = xml_node; end
  def name(); @name ||= @node.xpath('name')[0].text; end
  def tasks(); @node.xpath('tasks/task').collect { |t| Task.new(t) }; end
end

class Methodology
  include ActiveModel::Conversion
  include ActiveModel::Dirty
  include ActiveModel::Validations
  extend ActiveModel::Naming
  include Enumerable

  attr_accessor :content, :filename, :name, :updated_at

  validates_presence_of :content
  # validates_presence_of :name
  # validates_format_of :name, :with => /\A\w+[\w\s]*\z/
  validate :xml_syntax
  # FIXME: uncomment when we require all created methodologies to follow
  # v2 format (probably when all available templates are migrated)
  # validate :current_version

  # For ActiveModel::Dirty
  define_attribute_methods [:name]

  # -------------------------------------------------------------- Class config

  # Returns a Pathname to the location configured in the database through the
  # 'admin:paths:templates:methodologies' setting
  def self.pwd
    @pwd ||= Pathname.new(Configuration.paths_templates_methodologies)
  end

  # --------------------------------------------------------- ActiveModel::Lint

  # ActiveModel expects you to define an id() method to uniquely identify each
  # model
  def id() self.filename end
  def to_param() self.filename end

  def new_record?()
    # return true unless self.filename
    return !File.exist?(full_path)
  end

  # def destroyed?()  true end
  def persisted?()  false end

  # ---------------------------------------------------------------- Enumerable

  # When comparing two NoteTemplate instances, sort them alphabetically on their
  # name
  def <=>(other)
    self.name <=> other.name
  end

  # ------------------------------------------------------ ActiveRecord finders

  # Find by :id, which in this case is the file's basename
  def self.find(id)
    # Discard any input with weird characters
    if (id =~ /\A[\x00\/\\:\*\?\"<>\|]\z/)
      raise Exception.new('Not found!')
    end

    # Cycle through valid templates looking for a match
    found = false
    Dir[self.pwd.join('**.xml')].each do |file|
      next unless File.basename(file, '.xml') == id
      found = true
      break
    end
    raise Exception.new('Not found!') unless found

    # We've found it inside the self.pwd dir, so go ahead
    filename = self.pwd.join("#{id}.xml")
    return self.from_file(filename)
  end

  # Returns a collection of objects from the currently configured methodologies
  # path. See self.pwd()
  def self.all()
    Dir[self.pwd.join('**.xml')].collect do |file|
      self.from_file(file)
    end.sort
  end

  # -------------------------------------------------------------- Constructors

  # Creates an instance of Methodology from a given XML file.
  def self.from_file(filename)
    Methodology.new({
      filename: File.basename(filename, '.xml'),
      content: File.read(filename),
      updated_at: File.mtime(filename)
    })
  end

  # Constructor a la ActiveRecord. Attributes: :name, :file
  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end

  def save
    return false if !valid?
    FileUtils.mkdir_p(Methodology.pwd) unless File.exist?(Methodology.pwd)
    File.open(full_path, 'w') do |f|
      f << @content
    end
    return true
  end

  def destroy
    return true unless filename && File.exist?(full_path)
    File.delete(full_path)
    self
  end
  alias :delete :destroy

  def doc
    @doc ||= Nokogiri::XML(self.content)
  end

  def filename
    @filename ||= "auto_#{Time.now.to_i}"
  end

  def content
    if name_changed?
      doc.xpath('/*/name/text()')[0].replace(@name)
      @content = doc.to_s
      changes_applied
    end
    @content
  end

  def name
    @name ||= doc.xpath('/*/name').try(:text) || 'undefined'
  end

  def name=(new_name)
    name_will_change! unless new_name == @name
    @name = new_name
  end

  # TODO: this method should probably be replaced with #to_id() so we can use
  # the standard #dom_id() helper in the view.
  #
  # See:
  #   http://api.rubyonrails.org/v3.2.16/classes/ActionController/RecordIdentifier.html#method-i-dom_id
  #   http://api.rubyonrails.org/v3.2.16/classes/ActiveModel/Conversion.html#method-i-to_key
  def to_html_anchor
    [
      id,
      self.name.gsub(/[^0-9a-z\\s]/i, '').underscore
    ].join('-')
  end

  def version
    @version ||=
      if doc.root[:version].nil?
        doc.root.name == 'board' ? 2 : 1
      else
        doc.root[:version].to_i
      end
  end

  # ----------------------------------------------------- Sections, lists, tasks
  def lists
    doc.xpath('board/list').collect do |l|
      list = List.new(name: l.at('./name').text)
      l.xpath('./card').each do |c|
        list.cards.build(
          name: c.at_xpath('./name').try(:text),
          description: c.at_xpath('./description').try(:text)
        )
      end
      list
    end
  end

  def sections
    self.doc.xpath('methodology/sections/section').collect { |s| Section.new(s) }
  end

  # This should be replaced by a has_many association
  def tasks
    if version == 1
      sections.collect(&:tasks).flatten
    elsif version == 2
      lists.collect(&:cards).flatten
    end
  end

  def completed_tasks
    self.tasks.select { |task| task.checked? }
  end

  private
  def full_path
    Methodology.pwd.join("#{self.filename}.xml")
  end

  def xml_syntax
    xml = Nokogiri::XML(content)
    xml.errors.each do |error|
      errors.add(:base, error.message)
    end
  end

  def current_version
    errors.add(:version, 'must be 2') if version != 2
  end
end
