require 'RMagick'

class ImagesController < ApplicationController
  #upload_status_for :upload
  
  def image
    begin
      image = Image.find(params[:id])
    rescue 
      image = Image.find(Image::IMAGE_UNKNOWN_ID)
    ensure
     unless image.nil?
        size = params[:size]
        if !size.nil? and size.to_i > 0
          size = size.to_i
        else
          size = 128
        end
        tmp = Magick::Image.from_blob(image.data)[0]
        tmp.resize!(size,size)
        send_data(tmp.to_blob,
          :filename => image.name,
          :type => image.meta,
          :disposition => "inline") 
      end      
    end
  end
  
  def reload_code_image
    render :partial => "partials/captcha", :layout => false, 
      :locals => {:reload => params[:reload].to_i+1}
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
    font = 'arial'
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
      command << " -font #{font} -pointsize #{text_pen} -fill #{text_fg} -draw \"text #{text_pos_x},#{text_pos_y} '#{code[i-1].chr}'\""
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
    begin
      Image.transaction do
        @image = Image.new(params[:images])
        @image.save!
        type = Object.const_get(params[:type])
        obj = type.find(params[:id])
        old_id = obj.icon
        obj.icon=@image.id
        obj.save!
        old_img = Image.find(old_id)
        old_img.destroy unless old_img.nil?
      end
    rescue Exception 
      flash[:message] = _('image_upload_error')+ $!
    end
    redirect_to params[:back_to]
  end
  
  def new
    @image = Image.new
  end
  
  private  
  def generate_captcha_code(count=3)
    code=''
    seeds = ('A'..'Z').to_a
    count.downto(1){code<<seeds[rand(seeds.length)]}
    session[:captcha_code]=code
    code
  end
end
