module Cloudfinder
  module EC2
    class Cluster

      attr_reader(:cluster_name)

      # @param [Hash] args containing the cluster name and the instances
      # @return [Cloudfinder::EC2::Cluster]
      def initialize(args)
        @cluster_name = args[:cluster_name]
        @instances = args[:instances]
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
        instances.any? {|instance| instance.instance_id == instance_id}
      end

      # @return [Array<symbol>]
      def list_roles
        instances.group_by {|instance| instance.role}.keys
      end

      # @param [symbol] role
      # @return [Array<Cloudfinder::EC2::Instance>]
      def list_role_instances(role)
        instances.select {|instance| instance.role === role }
      end

      private

      # @return [Array<Cloudfinder::EC2::Instance>]
      def instances
        @instances
      end

    end
  end
end