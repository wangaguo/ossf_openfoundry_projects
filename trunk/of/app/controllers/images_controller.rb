class ImagesController < ApplicationController
  before_filter :login_required, :except => [:image, :code_image, :show,
    :reload_code_image, ]
  
  def image
    #get valid imag_id
    id = params[:id] || 0
    begin
      id = Image::IMAGE_UNKNOWN_ID unless Image.exists?(id)
    rescue
      id = Image::IMAGE_UNKNOWN_ID
    end
    #get valid image size
    size = params[:size] || '128'
    begin
      size = size.to_i
    rescue
      size = 128
    end

    image_cache_file = "#{Image::IMAGE_CACHES_DIR}/#{id}_#{size}"
    meta = Image.find(id).meta
    unless File.exists?(image_cache_file)
      image_data = "#{Image::IMAGE_DATA_DIR}/#{id}"
      `convert #{image_data}'[#{size}x#{size}]' #{image_cache_file}`

      #begin
      #  image = Image.find(id)
      #rescue 
      #  image = Image.find(Image::IMAGE_UNKNOWN_ID)
      #ensure
      #  tmp = Magick::Image.from_blob(image.data)[0]
      #  tmp.resize!(size,size)
      #  #tmp.write(image_cache_file)
      #  File.open(image_cache_file,"w+").write(tmp.to_blob)
      #  #send_data(tmp.to_blob,
      #  #  :filename => image.name,
      #  #  :type => image.meta,
      #  #  :disposition => "inline") 
      #end
    end
    send_file(image_cache_file, :type => meta, :disposition => "inline") 
  end
  
  def reload_code_image
    render :partial => "partials/captcha", :layout => false, 
      :locals => {:reload => params[:reload].to_i+1}
  end

  def email_image
    #tmp dir
    dir = RAILS_ROOT + "/tmp/email/"
    #if file exist, no regeneration
    email = session['email_image']
    filename = email.hash
    
    unless File.exist?([dir,filename,".jpg"].join)
      command = 'convert'
      
      #image params
      text_size = 25
      count = email.length
      width, height = text_size*count,text_size
      bg = 'white'
      font = 'Courier'
      
      #set image size
      command << " -size #{width}x#{height} xc:#{bg}"
      #set test color
      text_fg = "\"rgba(#{rand(128)},#{rand(128)},#{rand(128)},100)\""
      #text command
      command << "  -font #{font} -pointsize #{text_size} -fill #{text_fg} -draw \"text 0,#{text_size/4*3} '#{email}'\""
      
      @output = `#{command} -trim #{dir}#{filename}.jpg`
    end
    send_file([dir,filename,".jpg"].join, :type => 'image/jpeg', :disposition => 'inline')
    
  end
 
  def code_image
    #about imagick 'convert' command, see http://www.imagemagick.org/script/convert.php
    generate_captcha_code unless params[:not_regenerate]
    code = session[:captcha_code] || generate_captcha_code
    dir = RAILS_ROOT + "/tmp/captcha/"
    command = 'convert'
    
    #image params
    text_size = 50
    text_var = 0.6
    
    count = code.length
    width, height = text_size*count,text_size
    bg = 'white'
    font = 'Courier'
    amplitude, wavelength = height/(1.7+rand/3), width*(1.7+rand/3) 
    
    #set image size
    command << " -size #{width}x#{height} xc:#{bg}"
    #print code (random fg, randon size, random positions) 
    text_pos_x=0
    1.upto(count) do |i|
      text_pen = text_size*(1+text_var*(rand-1))
      text_pos_x+=text_pen/(1+rand)
      text_pos_y=text_pen
      text_fg = "\"rgba(#{rand(128)},#{rand(128)},#{rand(128)},100)\""
      command << "  -font #{font} -pointsize #{text_pen} -fill #{text_fg} -draw \"text #{text_pos_x},#{text_pos_y} '#{code[i-1].chr}'\""
    end
    #draw lines (10 lines, random fg, random positions)
#    1.upto(10) do |i|
#      line_fg = "\"rgb(#{rand(64)+64},#{rand(64)+64},#{rand(64)+64})\""
#      command << " -fill #{line_fg} -draw \"path 'M #{rand(width)},#{rand(height)} L #{rand(width)},#{rand(height)}'\""      
#    end
    #apply waves (3 waves, random directions) 
    1.upto(3) do
      rotate_degree = 180*rand
      command << " -rotate #{rotate_degree}"
      command << " -wave #{amplitude}x#{wavelength}"
      command << " -rotate #{-rotate_degree}"
    end
    
    @output = `#{command} -trim #{dir}#{code}.jpg`
    send_file([dir,code,".jpg"].join, :type => 'image/jpeg', :disposition => 'inline')
  end
    
  def show
    @image = Image.find(params[:id])
    render :layout => false
  end

  def create
    @image = Image.new(params[:images])
    if @image.save!
      redirect_to(:action => 'show', :id => @image.id)
    else
      render(:action => :new)
    end
  end

  def edit
    @image = Image.find(params[:id])
  end

  def upload
    allow=false
    if params[:type]=='User'
      allow = (current_user.id.to_s == params[:id])
    elsif params[:type]=='Project'
      allow = fpermit?("project_info", params[:id])
    end
   
    if allow
      begin
        Image.transaction do
          @image = Image.new(params[:images])
          @image.save!
          
          @image.save_to_file
          type = Object.const_get(params[:type])
          obj = type.find(params[:id])
          old_id = obj.icon
          obj.icon=@image.id
          obj.save!
          if(Image.exists?(old_id) and !site_reserved_image_id.include?(old_id))
            Image.find(old_id).destroy
          end
        end
      rescue Exception 
        flash[:message] = _('image_upload_error')+ $!
      end
    else
      flash[:message] = _('you have no permission')
    end
    redirect_to params[:back_to]
  end
  
  def new
    @image = Image.new
  end
  
  private  

  def site_reserved_image_id
    (1..100).to_a + [Image::IMAGE_UNKNOWN_ID]
  end

  def generate_captcha_code(count=3)
    code=''
    seeds = ('A'..'Z').to_a
    count.downto(1){code<<seeds[rand(seeds.length)]}
    session[:captcha_code]=code
    code
  end
end
