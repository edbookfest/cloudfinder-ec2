require 'open-uri'
module Cloudfinder
  module EC2
    class Detector
      EC2_METADATA_TIMEOUT  = 5
      EC2_METADATA_BASE_URL = 'http://169.254.169.254/latest/meta-data'

      # Detects the cluster for the current instance using the instance metadata service
      # and the AWS API to fetch tags.
      #
      # @return [Hash] with the cluster_name, cluster_role, instance_id and region
      def detect_cluster
        initialize_metadata
        result = {
            region:       @region,
            instance_id:  @instance_id,
            cluster_name: nil,
            cluster_role: nil
        }

        find_instance_tags.each do |tag|
          if tag[:key] === CLUSTER_TAG_NAME
            result[:cluster_name] = tag[:value]
          elsif tag[:key] === ROLE_TAG_NAME
            result[:cluster_role] = tag[:value].to_sym
          end
        end

        if result[:cluster_name].nil? || result[:cluster_role].nil?
          result[:cluster_name] = nil
          result[:cluster_role] = nil
        end

        result
      end

      private

      def initialize_metadata
        @instance_id = find_instance_id
        @region      = find_instance_region
      end

      # @return [Array<Hash>]
      def find_instance_tags
        ec2    = Aws::EC2::Client.new(region: @region)
        result = ec2.describe_tags(filters: [{ name: 'resource-id', values: [@instance_id] }])
        result[:tags]
      end

      # @return [string]
      def find_instance_region
        zone = get_metadata('/placement/availability-zone')
        zone[0, zone.length - 1]
      end

      # @return [string]
      def find_instance_id
        get_metadata('/instance-id')
      end

      # @param [string] path
      # @return [string]
      def get_metadata(path)
        open("#{EC2_METADATA_BASE_URL}#{path}", { read_timeout: EC2_METADATA_TIMEOUT }).read
      end
    end
  end
end