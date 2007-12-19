class ImagesController < ApplicationController
  
  def image
    image = Image.find(params[:id])
    send_data(image.data,
      :filename => image.name,
      :type => image.meta,
      :disposition => "inline") unless image.nil?
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
    @image = Image.new(params[:images])
    if @image.save!
      u=User.find(params[:user_id])
      u.icon=@image.id
      u.save
      #redirect_to(:action => 'show', :id => @image.id)
      redirect_to params[:back_to]
      #render :partial => 'images/edit', :lauout =>false, :locals => 
      #  {:image_id => @image.id, :user_id => u.id }
    end
  end
  
  def new
    @image = Image.new
  end
end
