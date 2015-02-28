module Cloudfinder
  module EC2
    class Clusterfinder

      # Find all the running instances for a named cluster and build them into a cluster object,
      # grouped by role.
      #
      # @param [Hash] query
      # @option query [string] :cluster_name find instances tagged with this cluster name
      # @option query [string] :region       EC2 region to search
      # @return [Cloudfinder::EC2::Cluster]
      def find(query)
        validate_arguments(query)
        @cluster_name = query[:cluster_name]
        instances     = []

        each_running_instance(query[:region]) do |instance_data|
          if in_cluster?(instance_data) && has_role?(instance_data)
            instances << new_instance(instance_data)
          end
        end

        Cloudfinder::EC2::Cluster.new(
            cluster_name: @cluster_name,
            instances:    instances
        )
      end

      private
      ERR_REGION_REQUIRED       = 'You must provide a :region argument to Instancefinder::find'
      ERR_CLUSTER_NAME_REQUIRED = 'You must provide a cluster_name argument to Instancefinder::find'

      # @param [Hash] args
      # @return [nil]
      def validate_arguments(args)
        raise(ArgumentError, ERR_REGION_REQUIRED) unless (args[:region])
        raise(ArgumentError, ERR_CLUSTER_NAME_REQUIRED) unless (args[:cluster_name])
      end

      # Find and iterate over all instances running in the given region
      #
      # @param [string] region
      # @return [Struct] instance data provided by AWS
      def each_running_instance(region)
        ec2    = Aws::EC2::Client.new(region: region)
        result = ec2.describe_instances(
            filters: [{ name: 'instance-state-name', values: ['running'] }]
        )

        result[:reservations].each do |reservation|
          reservation[:instances].each do |instance_data|
            yield instance_data
          end
        end
      end

      # @param [Struct] instance
      # @return [bool]
      def in_cluster?(instance)
        find_tag_value(instance, CLUSTER_TAG_NAME) === @cluster_name
      end


      # @param [Struct] instance
      # @return [bool]
      def has_role?(instance)
        instance.tags.any? { |tag| tag[:key] === ROLE_TAG_NAME }
      end

      # @param [Struct] instance
      # @return [Cloudfinder::EC2::Instance]
      def new_instance(instance)
        Cloudfinder::EC2::Instance.new(
            instance_id: instance[:instance_id],
            role:        find_tag_value(instance, ROLE_TAG_NAME).to_sym,
            public_ip:   instance[:public_ip_address],
            private_ip:  instance[:private_ip_address],
            public_dns:  instance[:public_dns_name],
            private_dns: instance[:private_dns_name],
        )
      end

      # @param [Struct] instance
      # @param [string] tag_key
      # @return [string]
      def find_tag_value(instance, tag_key)
        found_tag = instance.tags.select { |tag| tag[:key] === tag_key }
        if found_tag.empty?
          nil
        else
          found_tag.first[:value]
        end
      end

    end
  end
end
