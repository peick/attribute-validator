KLASSES = {
  'string'  => [ String ],
  'integer' => [ Integer ],
  'float'   => [ Float ],
  'number'  => [ Integer, Float ],
  'boolean' => [ TrueClass, FalseClass ],
  'array'   => [ Array ],
  'hash'    => [ Mash ],
  'nil'     => [ NilClass ],
}


class Chef
  class Attribute
    class Validator
      class Check
        class Type < Check


          register_check('type', Type)

          def validate_check_arg
            expected = KLASSES.keys()

            unless expected.include?(check_arg)
              raise "Bad 'type' check argument '#{check_arg}' for rule '#{rule_name}' - expected one of #{expected.join(',')}"
            end
          end

          def check(attrset)
            violations = []


            attrset.each do |path, value|
              next if value.nil?
              unless KLASSES[check_arg].any? {|k| value.kind_of?(k) }
                violations.push Chef::Attribute::Validator::Violation.new(rule_name, path, "Attribute's value is '#{value}', which does not appear to be the right type - expected '#{check_arg}'")
              end
            end

            violations
          end

        end
      end
    end
  end
end
