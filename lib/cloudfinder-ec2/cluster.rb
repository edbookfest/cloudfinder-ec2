module Cloudfinder
  module EC2
    class Cluster

      attr_reader(:cluster_name)

      # @param [Hash] args containing the cluster name and the instance data grouped by role
      # @return [Cloudfinder::EC2::Cluster]
      def initialize(args)
        @cluster_name = args[:cluster_name]
        @roles        = args[:role_instances]
      end

      # @return [bool]
      def empty?
        roles.empty?
      end

      # @return [bool]
      def running?
        ! empty?
      end

      # @param [symbol] role
      # @return [bool]
      def has_role?(role)
        roles.has_key?(role)
      end

      # @param [string] instance_id
      # @return [bool]
      def has_instance?(instance_id)
        all_instances do | instance |
          if instance[:instance_id] === instance_id
            return true
          end
        end

        false
      end


      # @return [Array<symbol>]
      def list_roles
        roles.keys
      end

      # @param [symbol] role
      # @return [Array<Hash>]
      def list_role_instances(role)
        if has_role?(role)
          roles[role]
        else
          []
        end
      end

      private

      # @return [Hash]
      def roles
        @roles
      end

      # @return [Hash]
      def all_instances
        roles.each do | rolename, role_instances |
          role_instances.each do | instance |
            yield instance
          end
        end
      end
    end
  end
end