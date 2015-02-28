require 'json'
module Cloudfinder
  module EC2
    module Command
      class List

        # Factory an instance of the list command with concrete dependencies
        #
        # @return [Object]
        def self.factory
          self.new(
              Cloudfinder::EC2::Clusterfinder.new,
              Cloudfinder::EC2::Detector.new,
              STDOUT,
              STDERR
          )
        end

        # @param [Cloudfinder::EC2::Clusterfinder] finder
        # @param [Cloudfinder::EC2::Detector] detector
        # @param [IO] stdout
        # @param [IO] stderr
        def initialize(finder, detector, stdout, stderr)
          @finder = finder
          @detector = detector
          @stdout = stdout
          @stderr = stderr
        end

        # Locates the roles and instances that make up a cluster, and prints the result to STDOUT
        # as JSON for consumption by other processes.
        #
        # If the cluster_name or region are not provided, it will attempt to detect the cluster
        # that the current instance belongs to (using the EC2 metadata service) and find other
        # instances in the same cluster.
        #
        # If cluster detection fails, an exception will be thrown
        #
        # @param [Hash] query
        # @option query [string] :cluster_name optionally specify cluster name to find
        # @option query [string] :region       optionally specify EC2 region to search
        # @return void
        def execute(query = {})
          unless query[:region] && query[:cluster_name]
            query = autodetect_cluster_or_throw.merge(query)
          end

          cluster = @finder.find(query)
          @stdout.puts(JSON.pretty_generate(cluster.to_hash))
        end

        private

        def autodetect_cluster_or_throw
          begin
            return @detector.detect_cluster
          rescue StandardError => e
            @stderr.puts('------------------------------------------------------------')
            @stderr.puts('| Automatic cluster detection error                        |')
            @stderr.puts('|----------------------------------------------------------|')
            @stderr.puts('| This instance may not be running on EC2, or there may be |')
            @stderr.puts('| a temporary issue with the EC2 metadata service. See the |')
            @stderr.puts('| exception message below for details.                     |')
            @stderr.puts('------------------------------------------------------------')
            raise e
          end
        end

      end
    end
  end
end