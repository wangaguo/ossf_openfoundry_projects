require 'gettext_textdomain_for_model'
class Survey < ActiveRecord::Base
  belongs_to :fileentity
  ITEM_STATUS = ['hidden', 'optional', 'mandatory'].freeze
  ITEMS = ['name', 'email', 'purpose', 'homepage', 'citation', 'contact',
           'occupation', 'age', 'interests', 'skills'] .freeze
  ITEM_COUNTS = 10

  def available?
    return( resource.index("1") or resource.index("2") ) 
  end

  def self.merge(survey ,ar,size = ITEM_COUNTS)
    raise ArgumentError unless ar.size == 2 and Survey === survey 
    rtn_resource='0'*size
    rtn_prompt=''
    r=survey.resource.ljust(size, '0')
    p=survey.prompt
    raise(ArgumentError,"#{r.inspect}") unless r.length == size 
    0.upto(size-1) do |i|
      rtn_resource[i] = ((r[i]-48) | (ar[0][i]-48)).to_s 
    end
     
    if ar[1].empty? or ar[1] == p
      rtn_prompt = p
    elsif p.nil? or p.empty?
      rtn_prompt = ar[1]
    else
      rtn_prompt = ar[1].to_s + "\n" + '-'*20 + "\n" + p.to_s
    end


    return [rtn_resource, rtn_prompt]
  end

  N_('survey|hidden')
  N_('survey|optional')
  N_('survey|mandatory')

  N_('survey|name')
  N_('survey|email')
  N_('survey|purpose')
  N_('survey|homepage')
  N_('survey|citation')
  N_('survey|contact')
  N_('survey|occupation')
  N_('survey|age')
  N_('survey|interests')
  N_('survey|skills')
end
