describe Cloudfinder::EC2::Detector do
  describe '#detect' do
    let (:ec2_client) { Aws::EC2::Client.new(stub_responses: true) }
    let (:tags) { [] }

    before (:each) do
      allow(Aws::EC2::Client).to receive(:new).and_return(ec2_client)
      ec2_client.stub_responses(:describe_tags, tags: tags)
    end

    context 'when instance metadata not available' do
      it 'throws exception on timeout' do
        allow(subject).to receive(:open).and_raise TimeoutError
        expect { subject.detect_cluster }.to raise_error(TimeoutError)
      end

      it 'throws exception on connection refused' do
        allow(subject).to receive(:open).and_raise Errno::ECONNREFUSED
        expect { subject.detect_cluster }.to raise_error(Errno::ECONNREFUSED)
      end

      it 'throws exception on 404' do
        allow(subject).to receive(:open).and_raise OpenURI::HTTPError.new('404', double('io'))
        expect { subject.detect_cluster }.to raise_error(OpenURI::HTTPError)
      end

      it 'throws exception on network unreachable' do
        allow(subject).to receive(:open).and_raise Errno::ENETUNREACH
        expect { subject.detect_cluster }.to raise_error(Errno::ENETUNREACH)
      end

    end

    shared_examples_for 'instance outside cluster' do
      include_examples 'instance with metadata'

      it 'returns a nil cluster name' do
        expect(subject.detect_cluster[:cluster_name]).to be_nil
      end

      it 'returns a nil cluster role' do
        expect(subject.detect_cluster[:cluster_name]).to be_nil
      end
    end

    shared_examples_for 'instance with metadata' do
      it 'returns the instance id' do
        expect(subject.detect_cluster[:instance_id]).to eq instance_id
      end

      it 'returns the AWS region' do
        expect(subject.detect_cluster[:region]).to eq region
      end
    end

    context 'when instance metadata available' do
      let (:instance_id) { 'i-00000001' }
      let (:availability_zone) { 'eu-west-1c' }
      let (:region) { 'eu-west-1' }

      before :each do
        stub_metadata('/placement/availability-zone', availability_zone)
        stub_metadata('/instance-id', instance_id)
      end

      context 'when searching for EC2 instances' do
        let (:ec2_client) { spy(Aws::EC2::Client) }

        it 'creates AWS API client for the specified region' do
          expect(Aws::EC2::Client).to receive(:new).with(region: region).once
          subject.detect_cluster
        end

        it 'requests the tags for this instance' do
          subject.detect_cluster
          expect(ec2_client).to have_received(:describe_tags).once.with(filters: [{ name: 'resource-id', values: [instance_id] }])
        end

      end

      context 'when AWS API throws exceptions' do
        it 'bubbles exceptions to caller' do
          ec2_client.stub_responses(:describe_tags, Aws::Errors::MissingCredentialsError)
          expect { subject.detect_cluster }.to raise_error(Aws::Errors::MissingCredentialsError)
        end
      end

      context 'when not part of cluster' do
        context 'when instance has no tags' do
          let (:tags) { [] }
          include_examples 'instance outside cluster'
        end

        context 'when instance only has irrelevant tags' do
          let (:tags) { [stub_tag('Name', 'anything')] }
          include_examples 'instance outside cluster'
        end

        context 'when instance has no cloudfinder-cluster tag' do
          let (:tags) { [stub_tag('cloudfinder-role', 'anything')] }
          include_examples 'instance outside cluster'
        end

        context 'when instance has no cloudfinder-role tag' do
          let (:tags) { [stub_tag('cloudfinder-cluster', 'anything')] }
          include_examples 'instance outside cluster'
        end
      end

      context 'when part of cluster' do
        let (:cluster_name) { 'qa' }
        let (:cluster_role) { 'app' }
        let (:tags) { [stub_tag('cloudfinder-cluster', cluster_name), stub_tag('cloudfinder-role', cluster_role)] }

        include_examples 'instance with metadata'

        it 'returns cluster name' do
          expect(subject.detect_cluster[:cluster_name]).to eq cluster_name
        end
        it 'returns cluster role' do
          expect(subject.detect_cluster[:cluster_role]).to eq cluster_role.to_sym
        end
      end
    end
  end

  def stub_metadata(path, response)
    url     = "http://169.254.169.254/latest/meta-data#{path}"
    timeout = Cloudfinder::EC2::Detector::EC2_METADATA_TIMEOUT
    allow(subject).to receive(:open).with(url, { read_timeout: timeout }).and_return FakeResponse.new(response)
  end

  def stub_tag(key, value)
    {
        key:   key,
        value: value
    }
  end

  class FakeResponse
    def initialize(body)
      @body = body
    end

    def read
      @body
    end
  end
end