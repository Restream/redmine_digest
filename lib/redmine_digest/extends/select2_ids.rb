module RedmineDigest
  module Extends
    module Select2Ids

      def select2_ids(association)

        define_method("select2_#{association}_ids=") do |comma_seperated_ids|
          self.send("#{association}_ids=", comma_seperated_ids.to_s.split(','))
        end

        define_method("select2_#{association}_ids") do
          send("#{association}_ids").join(',')
        end

      end
    end
  end
end

ActiveRecord::Base.extend RedmineDigest::Extends::Select2Ids
