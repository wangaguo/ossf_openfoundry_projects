require 'digest/md5'

class ImagesController < ApplicationController
  before_filter :login_required, :except => [:cached_image, :code_image, :show,
    :reload_code_image, ]
  
  session :off, :only => [:cached_image, :code_image, :show, :reload_code_image]

  def cached_image
    cache_name = params[:id]
    need_redirect = false
    id = Image::IMAGE_UNKNOWN_ID
    size = Image::IMAGE_DEFAULT_SIZE
    # match valid id and size
    cache_name =~ /^([u|p]?)(\d+)(?:_(\d+))?$/
    # normalize size  
    if $3
      size = $3.to_i
      unless (10..128).member? size
        # size exceed limitation
        size = (size < 10? 10:128)
        need_redirect = true
      end
    end
    # user/project icon?
    if $1 == ''
      #got image id
      id = $2.to_i
    else
      # user icon
      id = User.find($2).icon if User.exists?($2) if $1 == 'u'
      # project icon
      id = Project.find($2).icon if Project.exists?($2) if $1 =='p'
      need_redirect = true
    end

    # redirect image url because of u/p id or bad size or cache_name mismatch
    if need_redirect or "#{id}_#{size}" != cache_name
      redirect_to :id => "#{id}_#{size}"
      return
    end

    begin
      id = Image::IMAGE_UNKNOWN_ID unless Image.exists?(id)
    rescue
      id = Image::IMAGE_UNKNOWN_ID
    end

    image_cache_file = "#{Image::IMAGE_CACHES_DIR}/#{cache_name}"
    meta = Image.find(id).meta
    unless File.exists?(image_cache_file)
      image_data = "#{Image::IMAGE_DATA_DIR}/#{id}"
      `convert #{image_data}'[#{size}x#{size}]' #{image_cache_file}`

    end
    send_file(image_cache_file, :type => meta, :disposition => "inline") 
  end
  
  def reload_code_image
    render :partial => "partials/captcha", :layout => false, 
      :locals => {:reload => params[:reload].to_i+1}
  end

  def email_image
    #if file exist, no regeneration
    email = session['email_image']
    filename = "#{Image::IMAGE_EMAIL_DIR}/#{Digest::MD5.hexdigest(email)}"
   

    unless File.exist?(filename)
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
      command << " -font #{font} -pointsize #{text_size} -fill #{text_fg} -draw \"text 0,#{text_size/4*3} '#{email}'\""
      
      `#{command} -trim jpeg:#{filename}`

    end
    send_file(filename, :type => 'image/jpeg', :disposition => 'inline')
    
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
            #TODO delete cache
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
    #TODO optimize
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
