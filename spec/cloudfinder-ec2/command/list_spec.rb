describe Cloudfinder::EC2::Command::List, focus: true do
  let (:detector)         { spy(Cloudfinder::EC2::Detector) }
  let (:detector_result)  { { cluster_name: detected_cluster, cluster_role: 'db', region: detected_region } }
  let (:cluster_finder)   { spy(Cloudfinder::EC2::Clusterfinder) }
  let (:found_cluster)    { double(Cloudfinder::EC2::Cluster) }
  let (:cluster_hash)     { { cluster_name: detected_cluster, roles: {} } }
  let (:standard_out)     { StringIO.new }
  let (:error_out)        { StringIO.new }
  let (:detected_cluster) { 'qa' }
  let (:detected_region)  { 'eu-west-1' }

  subject do
    Cloudfinder::EC2::Command::List.new(
        cluster_finder,
        detector,
        standard_out,
        error_out
    )
  end

  before :each do
    allow(cluster_finder).to receive(:find).and_return found_cluster
    allow(found_cluster).to receive(:to_hash).and_return cluster_hash
  end

  shared_examples_for 'render cluster as JSON' do
    it 'prints cluster hash to standard out as JSON' do
      expect(JSON.parse(standard_out.string)).to eq stringify_keys(cluster_hash)
    end

    it 'prints nothing to standard error' do
      expect(error_out.string).to eq ''
    end
  end

  shared_examples_for 'find cluster by specified name' do |name|
    it 'finds cluster with specified cluster name' do
      expect(cluster_finder).to have_received(:find).with(hash_including(cluster_name: name))
    end
  end

  shared_examples_for 'find cluster by detected name' do
    it 'finds cluster with detected cluster name' do
      expect(cluster_finder).to have_received(:find).with(hash_including(cluster_name: detected_cluster))
    end
  end

  shared_examples_for 'find cluster in specified region' do |region|
    it 'finds cluster in specified region' do
      expect(cluster_finder).to have_received(:find).with(hash_including(region: region))
    end
  end

  shared_examples_for 'find cluster in detected region' do
    it 'finds cluster in detected region' do
      expect(cluster_finder).to have_received(:find).with(hash_including(region: detected_region))
    end
  end


  describe '#execute' do
    context 'when cluster name and region are specified' do
      before :each do
        subject.execute(cluster_name: 'other-cluster', region: 'custom-region')
      end

      it 'does not attempt automatic cluster detection' do
        expect(detector).not_to have_received(:detect_cluster)
      end

      include_examples('find cluster by specified name', 'other-cluster')
      include_examples('find cluster in specified region', 'custom-region')
      include_examples 'render cluster as JSON'
    end

    context 'when only cluster name is specified' do
      before :each do
        expect(detector).to receive(:detect_cluster).and_return detector_result
        subject.execute(cluster_name: 'other-cluster')
      end

      include_examples('find cluster by specified name', 'other-cluster')
      include_examples('find cluster in detected region')
      include_examples 'render cluster as JSON'
    end

    context 'when region is specified and cluster name can be detected' do
      before :each do
        expect(detector).to receive(:detect_cluster).and_return detector_result
        subject.execute(region: 'custom-region')
      end

      include_examples('find cluster by detected name')
      include_examples('find cluster in specified region', 'custom-region')
      include_examples 'render cluster as JSON'
    end

    context 'when specified region and cluster name are nil' do
      before :each do
        expect(detector).to receive(:detect_cluster).and_return detector_result
        subject.execute(region: nil, cluster_name: nil)
      end

      include_examples 'find cluster by detected name'
      include_examples 'find cluster in detected region'
      include_examples 'render cluster as JSON'
    end

    context 'when cluster detector throws exception' do
      before :each do
        expect(detector).to receive(:detect_cluster).and_raise Errno::ENETUNREACH
      end

      it 'rethrows the exception' do
        expect { subject.execute }.to raise_error Errno::ENETUNREACH
      end

      it 'prints nothing to standard out' do
        begin
          subject.execute rescue StandardError
        end
        expect(standard_out.string).to eq ''
      end

      it 'prints exception header to stderr' do
        begin
          subject.execute rescue StandardError
        end
        expect(error_out.string).to match /This instance may not be running on EC2/
      end
    end
  end

  def stringify_keys(hash)
    string_hash = {}
    hash.each do |key, value|
      string_hash[key.to_s] = value
    end
    string_hash
  end

end
