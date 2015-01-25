require_relative "chef-attribute-validator/version"
require_relative "chef-attribute-validator/violation"
require_relative "chef-attribute-validator/rule"
require_relative "chef-attribute-validator/attribute_set"

class Chef
  class Attribute
    class Validator

      #attr_accessor :node
      #attr_accessor :rules

      def initialize(a_node, rules)
        @node = a_node
        populate_rules(rules)
      end

      def validate_all
        violations = []
        @rules.each do |rulename, rule|
          violations += rule.apply(@node)
        end
        violations
      end

      def validate_rule(rulename)
        unless @rules.has_key?(rulename)
          raise "No such attribute validation rule named '#{rulename}' - have rules: #{@rules.keys.sort.join(',')}"
        end
        @rules[rulename].apply(@node)
      end

      def validate_matching(rule_regex)
        violations = []
        @rules.select { |rn,r| rule_regex.match(rn) }.each do |rulename, rule|
          violations += rule.apply(@node)
        end
        violations
      end

      private

      def populate_rules(rules)
        @rules = {}
        rules.each do |rulename, ruledef|
          @rules[rulename] = Chef::Attribute::Validator::Rule.new(rulename, ruledef)
        end
      end

      def self.validate(the_node, the_rules, fail_action='error')
        violas = Chef::Attribute::Validator.new(the_node, the_rules).validate_all()

        unless violas.empty?
          message  = "The node attributes for this chef run failed validation!\n"
          message += "A total of #{violas.size} violation(s) were encountered.\n"

          Chef::Log.warn(message)
          violas.each do |violation|
            snippet = violation.rule_name + ' at ' + violation.path + ': ' + violation.message
            message += snippet + "\n"
            if fail_action == 'warn'
              Chef::Log.warn 'Violation: ' + snippet
            end
          end

          if fail_action == 'error'
            fail message
          end
        end
      end

    end
  end
end
