module AdminView
  def generate_navigation
    html = ""
    if modules = get_modules
      modules.each do |tab|
        tab_name = get_tab_name
        selector = (tab_name == tab[:name].to_s) ? 'current' : 'available'        
        html << content_tag('li', 
                            link_to(content_tag('span', tab[:caption].humanize), tab[:url], :class => selector), 
                            :id => tab[:name] )
      end    
      content_tag('ul', html, :id => 'navs')
    else
      raise Exception, "Debe definir los módulos para la aplicación. Ver: http://code.google.com/p/administrateme/wiki/ConfiguracionDeModulos"
    end
  end
  
  def admin_file_loader
    html = ""
    html << file_loader_for(:css)
    html << file_loader_for(:javascript)
    html
  end
  
  def file_loader_for(type)
    html = ""    
    files_to_load(type).each do |file|
      html << file_inclusion(type, file)
    end    
    html
  end
  
  def files_to_load(type)
    if type == :css
      files = controller.respond_to?('admin_style') ? controller.admin_style : ["admin_look", "reset-fonts-grids"] 
    else    
      files = controller.respond_to?('admin_scripts') ? controller.admin_scripts : [:defaults, "admin_ui.js"]
    end
  end
  
  def file_inclusion(type, file)
    (type == :css) ? stylesheet_link_tag(file) : javascript_include_tag(file)
  end
  
  def get_modules
    if controller.respond_to?('modules')
      controller.instance_variable_set("@instance_modules", [])
      controller.modules
      controller.instance_variable_get("@instance_modules")
    else
      controller.class.ame_modules
    end
  end

  def get_tab_name
    if controller.respond_to?('tab')
      tname = controller.tab.to_s
    else
      tname = controller.controller_name.to_s
    end
  end
  
  def show_section_header
    show_section_label
  end
  
  def show_section_links
    links  = link_to( "Agregar nuevo registro", 
                      path_to_index(:new))
    if controller.options[:excel]
      links << link_to( "Descargar a Excel", eval("excel_#{controller.controller_name}_path"))
    end
    links
  end
  
  def show_section_label
    show_label("#{controller.controller_name.humanize}")
  end
  
  def show_label(label)
    content_tag('h1', label, :id => 'section_label')
  end
  
  def show_section_body
    content_tag('div', 
                render(:partial => 'list'), 
                :id => 'list_area')
  end
  
  def show_section_content
    html  = show_section_header
    html << content_tag('div', render(:partial => 'commons/search_form'), :id => 'search')
    html << show_section_body
    html
  end
    
  def show_mini_flash
    unless session[:mini].blank?      
      html  = content_tag('span', session[:mini])
      content_tag('div', html, :id => 'mini_flash')
    end
  end
  
  def path_to_index(*args)
    controller.path_to_index(*args)
  end
  
  def path_to_element(*args)
    controller.path_to_element(*args)
  end
      
  def generate_grid_table_for(options = {})
    unless @records.blank?    
      html = generate_grid_table_heads(options[:fields])
      
      body = ""
      for item in @records      
        cells = generate_grid_table_cells(item, options[:fields], options[:actions])
        body << content_tag('tr', cells, :id => "item_#{item.id}", :class => cycle('odd', 'even'))
      end
      
      html << body
      
      content_tag('table', html, :id => 'grid_table')
    else
      render_empty_msg
    end
  end 
  
  def generate_grid_table_heads(fields) 
    heads = ""
    fields.each do |field|
      heads << content_tag('th', field.humanize)
    end
    heads = content_tag('tr', heads)
    heads
  end
  
  def generate_grid_table_cells(item, fields, actions)
    cells = ""
    fields.each do |field|
      cells << content_tag('td', item.send(field))        
    end
    cells << generate_actions_links(item, actions)
    cells
  end
    
  
  def generate_actions_links(item, actions = [])
    name_space = controller.controller_name.singularize
    html = ""
    if actions
      if actions.include?('show')
        html << link_to(image_tag('show.png'), eval("#{name_space}_#{generate_path(item)}"), :title => 'ver más...')
#        html << link_to(image_tag('admin_ui/show.png'), eval("#{name_space}_#{generate_path(item)}"), :title => 'ver más...')
      end
      if actions.include?('edit')
        html << link_to(image_tag('edit.png'), eval("edit_#{name_space}_#{generate_path(item)}"), :title => 'editar este registro')
#        html << link_to(image_tag('admin_ui/edit.png'), eval("edit_#{name_space}_#{generate_path(item)}"), :title => 'editar este registro')
      end
      if actions.include?('destroy')
        html << link_to(image_tag('destroy.png'), eval("#{name_space}_#{generate_path(item)}"), :confirm => 'El registro será eliminado definitivamente. ¿Desea continuar?', :method => :delete, :title => 'eliminar este registro')
#        html << link_to(image_tag('admin_ui/destroy.png'), eval("#{name_space}_#{generate_path(item)}"), :confirm => 'El registro será eliminado definitivamente. ¿Desea continuar?', :method => :delete, :title => 'eliminar este registro')
      end
      unless html.blank?
        html = content_tag('div', html, :align => 'right')     
        html = content_tag('td', html)
      end
    end
    html
  end
  
  def generate_path(item)
    path = "path("
    unless controller.options[:parent].blank?
      path << "@parent.id,"
    end
    path << "item)"
    path
  end
  
  def search_url
    str  = "{:action=>'search', "
    unless controller.options[:parent].blank?
      str << ":#{controller.options[:parent].to_s}_id => params[:#{controller.options[:parent].to_s}_id],"
    end
    str << ":only_path => false}"
    eval(str)
  end  
  
  def search_scope
    "(#{controller.options[:search].map{|x| x.to_s.humanize}.join(', ')})"
  end
  
  def render_flash_message
    html = ""
    if flash[:notice] || flash[:error]    
      html = content_tag('div', flash[:notice], :class => 'success') unless flash[:notice].blank?
      html = content_tag('div', flash[:error],  :class => 'error')   unless flash[:error].blank?
      html = content_tag('div', html, :id => 'flash')
    end
    html
  end
  
  def html
    aux = {}
    if controller.respond_to?('form_settings')
      aux = controller.form_settings
    end
    aux[:method] = :put if ['edit', 'update'].include?(controller.action_name)
    aux[:id] = controller.model_name
    aux
  end
  
  def show_filters_for(filters = [])
    html = ""
    lis  = ""
    unless filters.blank?
      html << content_tag(:div, 'Filtrar registros por...', :class => 'f_header')     
      filters.each do |filter|
        link = link_to(filter[:caption], filter[:url])
        lis << content_tag(:li, link, :class => set_current(filter[:name_space]))
      end
      html << content_tag(:ul, lis, :class => 'filters')
    end
    html
  end 

  def list_for(group, settings = {})
    header  = (settings[:label]) ? settings[:label] : group.to_s.humanize
    html    = content_tag(:div, header, :class => 'header')    
    settings[:collection].each do |item|
      aux   = (settings[:not_show]) ? '#' : link_to_show(group, item, settings)
      link  = link_to(item.send(settings[:field]), aux)
      html << content_tag(:li, link, :class => cycle('odd', 'even') )
    end
    html  = content_tag(:ul, html, :id => 'list')
    html << link_to_more(settings[:link]) if settings[:link]
    html
  end
  
  def link_to_show(group, item, options)
    controller_name = options[:controller_name] || group.to_s.singularize
    namespace = options[:namespace] || controller.class.namespace
    new_options = options.dup
    new_options[:parent] = new_options.delete(:parent_name)
    controller.send(:create_path, controller_name, item, namespace, options[:parent], new_options)
  end
  
  def link_to_more(ltmore)
    html = link_to('administrar', ltmore)
    content_tag(:div, html, :class => 'more')
  end
  
  def set_current(name_space)
    if name_space == session[:c_filter]
      css = "current"
    else
      css = nil
    end
    css
  end
  
end

ActionView::Base.send :include, AdminView
