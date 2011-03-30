class Image < ActiveRecord::Base
  IMAGE_UPLOAD_SIZE_LIMIT = 3.megabyte
  IMAGE_UNKNOWN_ID = 1
  IMAGE_DEFAULT_USER_ICON = 1
  IMAGE_DEFAULT_PROJECT_ICON = 2
  IMAGE_DEFAULT_SIZE = 128
  IMAGE_CACHES_DIR = "#{Rails.root.to_s}/public/images/cached_image"
  IMAGE_DATA_DIR = "#{Rails.root.to_s}/tmp/image_data"
  IMAGE_EMAIL_DIR = "#{Rails.root.to_s}/public/images/email_image"

  validates_format_of :meta, :with => /^image/,
    :message => _("Image|Picture only")

  # For convert to cache, need save source to temp.
  def save_to_file
    f = File.open("#{IMAGE_DATA_DIR}/#{self.id}","w")
    f.write(self.data)
    f.close
  end
 
  # When image uploaded then convert 4 size to cache.
  def convert_image
    [16, 32, 64, 128].each do |size|
      convert_to_cache(size)
    end
  end

  # Convert image_size to cache.
  def convert_to_cache(size)
    image_cache_file = "#{Image::IMAGE_CACHES_DIR}/#{self.id}_#{size}"
    meta = self.meta
    unless File.exists?(image_cache_file)
      image_data = "#{Image::IMAGE_DATA_DIR}/#{self.id}"
      unless File.exists?(image_data)
        save_to_file
      end
      ico = if(meta =~ /icon/); 'ico:' ;else '' ;end
      if system("/usr/local/bin/convert #{ico}#{image_data}'[#{size}x#{size}]' #{image_cache_file}") == false
        logger.error("image convert error. cmd: 'convert #{image_data}'[#{size}x#{size}]' #{image_cache_file}'")
        false
      else
        true
      end
    else
      false
    end
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
