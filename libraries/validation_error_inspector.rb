class Chef

  module EventDispatch
    class Base
      # Called when an attribute fails validation
      def attribute_validation_failed(violation)
      end
    end
    Dispatcher.def_forwarding_method(:attribute_validation_failed)
  end


  module Formatters

    module ErrorMapper

      def self.attribute_validation_failed(node_name, exception, config)
        error_inspector = ErrorInspectors::ValidationErrorInspector.new(node_name, exception, config)
        headline = "Chef encountered an attribute validation error."
        description = ErrorDescription.new(headline)
        error_inspector.add_explanation(description)
        return description
      end
    end

    module ErrorInspectors
      # == ValidationErrorInspector
      # Wraps exceptions that occur while running attribute validation.
      class ValidationErrorInspector

        attr_reader :path
        attr_reader :exception

        def initialize(path, exception)
          @path, @exception = path, exception
        end

        def add_explanation(error_description)
          case exception
          when Chef::Exceptions::RecipeNotFound
            error_description.section(exception.class.name, exception.message)
          else
            error_description.section(exception.class.name, exception.message)

            traceback = filtered_bt.map {|line| "  #{line}"}.join("\n")
            error_description.section("Cookbook Trace:", traceback)
            error_description.section("Relevant File Content:", context)
          end
        end

        def context
          context_lines = []
          context_lines << "#{culprit_file}:\n\n"
          Range.new(display_lower_bound, display_upper_bound).each do |i|
            line_nr = (i + 1).to_s.rjust(3)
            indicator = (i + 1) == culprit_line ? ">> " : ":  "
            context_lines << "#{line_nr}#{indicator}#{file_lines[i]}"
          end
          context_lines.join("")
        end

        def display_lower_bound
          lower = (culprit_line - 8)
          lower = 0 if lower < 0
          lower
        end

        def display_upper_bound
          upper = (culprit_line + 8)
          upper = file_lines.size if upper > file_lines.size
          upper
        end

        def file_lines
          @file_lines ||= IO.readlines(culprit_file)
        end

        def culprit_backtrace_entry
          @culprit_backtrace_entry ||= begin
             bt_entry = filtered_bt.first
             Chef::Log.debug("backtrace entry for compile error: '#{bt_entry}'")
             bt_entry
          end
        end

        def culprit_line
          @culprit_line ||= begin
            line_number = culprit_backtrace_entry[/^(?:.\:)?[^:]+:([\d]+)/,1].to_i
            Chef::Log.debug("Line number of compile error: '#{line_number}'")
            line_number
          end
        end

        def culprit_file
          @culprit_file ||= culprit_backtrace_entry[/^((?:.\:)?[^:]+):([\d]+)/,1]
        end

        def filtered_bt
          filters = Array(Chef::Config.cookbook_path).map {|p| /^#{Regexp.escape(p)}/ }
          r = exception.backtrace.select {|line| filters.any? {|filter| line =~ filter }}
          Chef::Log.debug("filtered backtrace of compile error: #{r.join(",")}")
          return r.count > 0 ? r : exception.backtrace
        end

      end

    end
  end
end
