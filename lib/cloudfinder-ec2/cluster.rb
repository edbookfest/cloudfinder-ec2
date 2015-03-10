module Cloudfinder
  module EC2
    class Cluster

      attr_reader(:cluster_name)

      # @param [Hash] args containing the cluster name and the instances
      # @return [Cloudfinder::EC2::Cluster]
      def initialize(args)
        @cluster_name = args[:cluster_name]
        @instances    = args[:instances]
      end

      # @return [bool]
      def empty?
        instances.empty?
      end

      # @return [bool]
      def running?
        !empty?
      end

      # @param [symbol] role
      # @return [bool]
      def has_role?(role)
        list_roles.include?(role)
      end

      # @param [string] instance_id
      # @return [bool]
      def has_instance?(instance_id)
        instances.any? { |instance| instance.instance_id == instance_id }
      end

      def get_instance(instance_id)
        found_instances = instances.select { |instance| instance.instance_id == instance_id }
        raise(RangeError, "#{instance_id} is not part of the #{@cluster_name} cluster") if found_instances.empty?
        found_instances.first
      end

      # @return [Array<symbol>]
      def list_roles
        instances.group_by { |instance| instance.role }.keys
      end

      # @return [Array<Cloudfinder::EC2::Instance>]
      def list_instances
        instances
      end

      # @param [symbol] role
      # @return [Array<Cloudfinder::EC2::Instance>]
      def list_role_instances(role)
        instances.select { |instance| instance.role === role }
      end

      # Return the current cluster as a simple nested hash, suitable for rendering to JSON or similar
      #
      #   {
      #      cluster_name: 'production',
      #      roles: {
      #        db: [
      #           {instance_id: 'i-00000001', public_ip: '123.456.789.123',...}
      #        ]
      #      }
      #   }
      #
      # @return [Hash]
      def to_hash
        hash = {
            cluster_name: @cluster_name,
            roles:        {}
        }

        instances.each do |instance|
          hash[:roles][instance.role] = [] unless hash[:roles][instance.role]
          hash[:roles][instance.role] << instance.to_hash
        end

        hash
      end

      private

      # @return [Array<Cloudfinder::EC2::Instance>]
      def instances
        @instances
      end

    end
  end
end