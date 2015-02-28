module Cloudfinder
  module EC2
    class Instance
      attr_reader(:instance_id)
      attr_reader(:public_ip)
      attr_reader(:public_dns)
      attr_reader(:private_ip)
      attr_reader(:private_dns)
      attr_reader(:role)

      # @param [Hash<string>] instance attributes
      def initialize(data)
        @instance_id = data[:instance_id].freeze
        @public_ip   = data[:public_ip].freeze
        @public_dns  = data[:public_dns].freeze
        @private_ip  = data[:private_ip].freeze
        @private_dns = data[:private_dns].freeze
        @role        = data[:role]
      end

      # @return [Hash<string>]
      def to_hash
        {
            instance_id: @instance_id,
            public_ip:   @public_ip,
            public_dns:  @public_dns,
            private_dns: @private_dns,
            private_ip:  @private_ip,
            role:        @role
        }
      end
    end
  end
end
