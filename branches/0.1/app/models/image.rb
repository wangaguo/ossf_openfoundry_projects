require 'RMagick'

class Image < ActiveRecord::Base
  IMAGE_UNKNOWN_ID = 65535
  
  validates_format_of :meta, :with => /^image/,
    :message => "picture only"

  def image=(picture_field)
    self.name = base_part_of(picture_field.original_filename)
    self.meta = picture_field.content_type.chomp
    self.data = picture_field.read
    
    #縮圖!
    img = Magick::Image.from_blob(self.data).first
    self.data = img.resize!(128,128).to_blob
  end
  
  def base_part_of(file_name)
    name = File.basename(file_name)
    name.gsub(/[^\w._-]/, '')
  end
end
