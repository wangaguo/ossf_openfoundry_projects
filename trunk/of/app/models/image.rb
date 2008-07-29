class Image < ActiveRecord::Base
  IMAGE_UNKNOWN_ID = 65535
  IMAGE_CACHES_DIR = "#{RAILS_ROOT}/public/images/cached_image"
  IMAGE_DATA_DIR = "#{RAILS_ROOT}/tmp/image_data"
  IMAGE_EMAIL_DIR = "#{RAILS_ROOT}/public/images/email_image"

  validates_format_of :meta, :with => /^image/,
    :message => _("Image|Picture only")

  def save_to_file
    File.open("#{IMAGE_DATA_DIR}/#{self.id}","w+").write(self.data)
  end

  def image=(picture_field)
    self.name = base_part_of(picture_field.original_filename)
    self.meta = picture_field.content_type.chomp
    self.data = picture_field.read
    
    #縮圖!
    #img = Magick::Image.from_blob(self.data).first
    #self.data = img.resize!(128,128).to_blob

  end
  
  def base_part_of(file_name)
    name = File.basename(file_name)
    name.gsub(/[^\w._-]/, '')
  end
end
