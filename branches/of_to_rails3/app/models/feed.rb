class Feed 
  extend ActiveModel::Naming
  include ActiveModel::Conversion

  include ActiveModel::AttributeMethods
  define_attribute_methods ['title', 'description', 'date', 'link']
  attr_accessor :title, :description, :date, :link

  def valid?() true end

  def errors 
    @errors ||= ActiveModel::Errors.new(self)
  end

  def persisted?
    false
  end

  def initialize(attributes = {})
    if attributes.present?
      attributes.each { |k, v| send("#{k}=", v) if respond_to?("#{k}=") }
    end
  end
end

