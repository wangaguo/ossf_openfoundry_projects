module UserHelper

  def user_portrait_link(user, options={})
    "<a href=/user/home/#{user.id}><img src=\"#{url_for(:controller => :images, :action => "image", :id => user.icon, :size => options[:size]||32)} \"/></a>"
  end


#  DEFAULT_HEAD_OPTIONS = {
#    :notice => true,
#    :message => true,
#    :error => false
#  }.freeze
#
#  # Abstraction to make views a little cleaner
#  def form_input(helper_method, field_name, options = {}, form_name = nil)
#    form_name = "user" if form_name.nil?
#    case helper_method.to_s
#    when 'hidden_field'
#      self.hidden_field(form_name, field_name, options)
#    when /^.*button$/
#      prompt = _("#{@controller.controller_name}_#{field_name}_button")
#      <<-EOL
#      <tr><td class="button" colspan="2">
#        #{self.send(helper_method, form_name, prompt, options)}
#      </td></tr>
#      EOL
#    else
#      field = (
#        case helper_method
#        when :select
#          self.send(helper_method, form_name, field_name, options.delete('values'), options)
#        when :password_field
#          options[:value] = ""
#          self.send(helper_method, form_name, field_name, options)
#        else
#          self.send(helper_method, form_name, field_name, options)
#        end)
#      lname = "#{form_name}_#{field_name}_form"
#      prompt = _("#{lname}")
#      if UserSystem::CONFIG[:two_column_input]
#<<-EOL
#        <tr class="two_columns">
#          <td class="prompt"><label>#{prompt}:</label></td>
#          <td class="value">#{field}</td>
#        </tr>
#        EOL
#      else
#<<-EOL
#        <tr><td class="prompt"><label>#{prompt}:</label></td></tr>
#        <tr><td class="value">#{field}</td></tr>
#        EOL
#      end
#    end
#  end
#
#  def button_helper(name, options = {})
#    label = _("#{@controller.controller_name}_#{name}_button")
#    "#{self.send(:submit_tag, label, options)}"
#  end
#
#  def link_helper(name, options = {})
#    raise ArgumentError if name.nil?
#    label = _("#{@controller.controller_name}_#{name}_link")
#    "#{self.send(:link_to, label, options)}"
#  end
#
#  def title_helper
#    "#{@controller.controller_class_name} #{@controller.action_name}"
#  end
#
#  def head_helper(options = {})
#    label = _("#{@controller.controller_name}_#{@controller.action_name}_head")
#    notice = message = error = nil
#    opts = DEFAULT_HEAD_OPTIONS.dup
#    opts.update(options.symbolize_keys)
#    s = "<h3>#{label}</h3>"
#    if flash['notice'] and not opts[:notice].nil? and opts[:notice]
#      notice = "<div><p>#{flash['notice']}</p></div>"
#      s = s + notice
#    end
#    if flash['message'] and not opts[:message].nil? and opts[:message]
#      message = "<div id=\"ErrorExplanation\"><p>#{flash['message']}</p></div>"
#      s = s + message
#    end
#    if not opts[:error].nil? and opts[:error]
#     error = error_messages_for('user')
#     if not error.nil?
#       error = error + "<br/>"
#       s = s + error
#     end
#   end
#   return s
#<<-EOL
#    <h3>#{label}</h3>
#    #{notice}
#    #{message}
#    #{error}
#EOL
#  end
#
#  def message_helper(name)
#    _("#{@controller.controller_name}_#{name}_message")
#  end
#
#  def start_form_tag_helper(&blk)
#    url = url_for(:action => "#{@controller.action_name}")
#    "#{self.send(:form_tag, url, &blk)}"
#  end
#
#  def attributes(hash)
#    hash.keys.inject("") { |attrs, key| attrs + %{#{key}="#{h(hash[key])}" } }
#  end
#
#  def read_only_field(form_name, field_name, html_options)
#    "<span #{attributes(html_options)}>#{instance_variable_get('@' + form_name)[field_name]}</span>"
#  end
#  
#  def submit_button(form_name, prompt, html_options)
#    %{<input name="submit" type="submit" value="#{prompt}" />}
#  end
#
#  def changeable(user, field)
#    if user.new_record? or UserSystem::CONFIG[:changeable_fields].include?(field)
#      :text_field
#    else
#      :read_only_field
#    end
#  end
end
