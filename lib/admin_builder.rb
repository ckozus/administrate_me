class AdminBuilder < ActionView::Helpers::FormBuilder
    attr_reader :options
    
    def initialize(object_name, object, template, options, proc)
      super
      @options[:show_nil] = true if @options[:show_nil].nil?
      @form_columns = []
    end
  
    (field_helpers - %w(check_box radio_button hidden_field)).each do |selector|
      define_method(selector) do |*params|
        fld = params[0]
        options = params[1] || {}
        return '' if no_show?(fld, options)
        if read_only(options)
          field(fld, options)
        else
          options = set_class(options)
          wrapper(fld, label(fld, options)+ super(fld, options), options)
        end
      end
    end
    
    def hidden_field(fld, options = {})
      return '' if no_show?(fld, options)
      super(fld, options)
    end
    
    def check_box(fld, options = {})
      return '' if no_show?(fld, options)
      if read_only(options)
        field(fld, options)
      else
        options = set_class(options, 'check_box')
        wrapper(fld, super(fld, options) + label(fld, options), options.merge(:check_box => true))
      end
    end
    
    def select(fld, choices, options = {}, html_options = {})
      return '' if no_show?(fld, options)
      if read_only(options)
        field(fld, options)
      else
        options = set_class(options)
        html_options = set_class(html_options.merge(:columns => options[:columns]))
        wrapper(fld, label(fld, options)+ super(fld, choices, options, html_options), options)
      end
    end

    def date_select(fld, options = {})
      return '' if no_show?(fld, options)
      if read_only(options)
        field(fld, options)
      else
        options = {:order => [:day, :month, :year]}.merge(set_class(options))
        wrapper(fld, label(fld, options) +  
                @template.content_tag(:span, super, :class => 'date_entrada'),
                options)
      end
    end
 
    def datetime_select(fld, options = {})
      return '' if no_show?(fld, options)
      if read_only(options)
        field(fld, options)
      else
        options = set_class(options)
        wrapper(fld, label(fld, options) +  
                @template.content_tag(:span, super, :class => 'date_entrada'),
                options)
      end
    end
    
    def select_time(fld, options = {})
      return '' if no_show?(fld, options)
      if read_only(options)
        field(fld, options.merge(:read_only => true))
      else
        options = set_class(options).merge(:prefix => fld)
        wrapper(fld, label(fld, options) + 
                      @template.content_tag(:span, @template.select_time(fld_value(fld, options), options), 
                                            :class => 'date_entrada'),
                      options)
      end
    end
    
    def field(fld, options = {})
      return '' if no_show?(fld, options)
      if fld.to_s =~ /([\w]+)_id$/
        fld = $1.to_sym
      end
      opts = options[:highlight] ? {:span => {:class => 'highlight'}} : {}
      opts.delete(:columns)
      opts[:label] = {:id => 'label_' + @object_name.to_s + fld.to_s}
      opts[:label].merge! :style => 'display:none' if options[:hidden]
      @template.field_label_tag(label(fld, options), fld_value(fld, options).to_s, opts)
    end

    private

      def fld_value(fld, options = {})
        rtn = @object.send(fld)
        rtn = rtn.strftime('%H:%M') if rtn && options[:format] == :hour && options[:read_only]
        rtn = rtn ? 'SI' : 'NO' if rtn == true || rtn == false
        rtn
      end

      # Permitir que cuando se muestre un campo, si es nulo, no se lo muetre (:show_nil)
      def no_show?(fld, options)
        fld_value(fld).nil? && read_only(options) && @options[:show_nil] == false
      end
      
      def read_only(options)
        false
      end

      def set_class(options, default = nil)
        options[:class] = default || options[:class]
        options
      end
      
      def label(fld, options)
        @template.content_tag(:label, options[:label] || fld.to_s.humanize, :class => 'label', :for => "#{@object_name}_#{fld}") + "<br/>"
      end

      def wrapper(fld, text, options)
        id = @object.class.to_s.underscore + '_' + fld.to_s
        opts = {:id => "div_#{id}"}
        opts.merge! :style => 'display:none;' if options[:hidden]
        opts[:class] = 'check_box' if options[:check_box]
        spnr = options[:spinner] ? @template.spinner("#{id}_spinner") : ''
        @template.content_tag(:div, text + spnr, opts)
      end
      
  end