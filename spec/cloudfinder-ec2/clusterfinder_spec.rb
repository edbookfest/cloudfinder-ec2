describe Cloudfinder::EC2::Clusterfinder do

  let (:client)       { Aws::EC2::Client.new(stub_responses: true) }
  let (:reservations) { [] }
  let (:cluster_name) { 'production' }
  let (:region)       { 'some-region' }

  before (:each) do
    allow(Aws::EC2::Client).to receive(:new).and_return(client)
  end

  shared_examples_for 'cluster object response' do
    it 'provides cluster name in returned cluster' do
      expect(cluster.cluster_name).to eq cluster_name
    end
  end

  shared_examples_for 'empty cluster' do
    include_examples 'cluster object response'

    it 'returns empty cluster' do
      expect(cluster).to be_empty
    end
  end

  shared_examples_for 'running cluster with roles' do |roles|
    include_examples 'cluster object response'

    it 'returns running cluster' do
      expect(cluster).to be_running
    end

    it 'has only the expected cluster roles' do
      expect(cluster.list_roles).to eq roles
    end
  end

  shared_examples_for 'cluster with instance in role' do |role, instance_index, instance_id|
    it "has #{role} role in cluster" do
      expect(cluster).to have_role(role)
    end

    it "has instance #{instance_id} as #{role}:##{instance_index}" do
      expect(cluster.list_role_instances(role)[instance_index].instance_id).to eq instance_id
    end

    it "populates #{instance_id} public IP" do
      expect(cluster.list_role_instances(role)[instance_index].public_ip).to eq public_ip(instance_id)
    end

    it "populates #{instance_id} private IP" do
      expect(cluster.list_role_instances(role)[instance_index].private_ip).to eq private_ip(instance_id)
    end

    it "populates #{instance_id} public DNS" do
      expect(cluster.list_role_instances(role)[instance_index].public_dns).to eq public_dns(instance_id)
    end

    it "populates #{instance_id} private DNS" do
      expect(cluster.list_role_instances(role)[instance_index].private_dns).to eq private_dns(instance_id)
    end
  end

  describe '#find' do
    let (:cluster) { subject.find(region: region, cluster_name: cluster_name) }

    context 'with invalid arguments' do
      it 'throws without region' do
        expect { subject.find(cluster_name: cluster_name) }.to raise_error(ArgumentError)
      end

      it 'throws without cluster name' do
        expect { subject.find(region: region) }.to raise_error(ArgumentError)
      end
    end

    context 'when searching for EC2 instances' do
      let (:client) { spy(Aws::EC2::Client) }

      it 'creates AWS API client for the specified region' do
        expect(Aws::EC2::Client).to receive(:new).with(region: 'any-region').once.and_return(client)
        subject.find(region: 'any-region', cluster_name: cluster_name)
      end

      it 'requests details of running EC2 instances' do
        subject.find(region: 'us-east-1', cluster_name: 'i12345678')
        expect(client).to have_received(:describe_instances).once.with(filters: [{ name: 'instance-state-name', values: ['running'] }])
      end
    end

    context 'when AWS API throws exceptions' do
      it 'bubbles exceptions to caller' do
        client.stub_responses(:describe_instances, Aws::Errors::MissingCredentialsError)
        expect { subject.find(region: 'us-east-1', cluster_name: 'any') }.to raise_error(Aws::Errors::MissingCredentialsError)
      end
    end

    context 'when no instances are running' do
      before (:each) do
        client.stub_responses(:describe_instances, reservations: [])
      end

      include_examples 'empty cluster'
    end

    context 'when one instance is running' do
      before (:each) do
        stub_describe_instances(stub_reservation(running_instance))
      end

      context 'with no tags' do
        let(:running_instance) { stub_instance }
        include_examples 'empty cluster'
      end

      context 'with irrelevant tags' do
        let(:running_instance) { stub_instance(tags: { 'name' => 'qa-server' }) }
        include_examples 'empty cluster'
      end

      context 'with cloudfinder-cluster tag for another cluster' do
        let(:running_instance) { stub_instance(cluster_tag: 'another-cluster', role_tag: 'db') }
        include_examples 'empty cluster'
      end

      context 'tagged for correct cloudfinder-cluster without cloudfinder-role' do
        let(:running_instance) { stub_instance(cluster_tag: cluster_name, role_tag: nil) }
        include_examples 'empty cluster'
      end

      context 'tagged for correct cloudfinder-cluster with cloudfinder-role=db' do
        let(:running_instance) { stub_instance(id: 'i-00000001', cluster_tag: cluster_name, role_tag: 'db') }

        include_examples('running cluster with roles', [:db])
        include_examples('cluster with instance in role', :db, 0, 'i-00000001')
      end
    end

    context 'when two instances in single reservation' do
      before (:each) do
        stub_describe_instances(stub_reservation(instance_1, instance_2))
      end

      context 'with only one in this cluster' do
        let (:instance_1) { stub_instance(id: 'i-00000001', cluster_tag: cluster_name, role_tag: 'db') }
        let (:instance_2) { stub_instance(id: 'i-00000002', cluster_tag: 'another-cluster', role_tag: 'app') }

        include_examples('running cluster with roles', [:db])
        include_examples('cluster with instance in role', :db, 0, 'i-00000001')
      end

      context 'both in this cluster with same role' do
        let (:instance_1) { stub_instance(id: 'i-00000001', cluster_tag: cluster_name, role_tag: 'db') }
        let (:instance_2) { stub_instance(id: 'i-00000002', cluster_tag: cluster_name, role_tag: 'db') }

        include_examples('running cluster with roles', [:db])
        include_examples('cluster with instance in role', :db, 0, 'i-00000001')
        include_examples('cluster with instance in role', :db, 1, 'i-00000002')
      end

      context 'both in this cluster with different roles' do
        let (:instance_1) { stub_instance(id: 'i-00000001', cluster_tag: cluster_name, role_tag: 'db') }
        let (:instance_2) { stub_instance(id: 'i-00000002', cluster_tag: cluster_name, role_tag: 'app') }

        include_examples('running cluster with roles', [:db, :app])
        include_examples('cluster with instance in role', :db, 0, 'i-00000001')
        include_examples('cluster with instance in role', :app, 0, 'i-00000002')
      end
    end

    context 'when three instances in two reservations' do
      before (:each) do
        stub_describe_instances(
            stub_reservation(instance_1, instance_2),
            stub_reservation(instance_3)
        )
      end

      context 'with only two in this cluster' do
        let (:instance_1) { stub_instance(id: 'i-00000001', cluster_tag: 'another-cluster', role_tag: 'db') }
        let (:instance_2) { stub_instance(id: 'i-00000002', cluster_tag: 'another-cluster', role_tag: 'app') }
        let (:instance_3) { stub_instance(id: 'i-00000003', cluster_tag: cluster_name, role_tag: 'app') }

        include_examples('running cluster with roles', [:app])
        include_examples('cluster with instance in role', :app, 0, 'i-00000003')
      end

      context 'all in this cluster with same role' do
        let (:instance_1) { stub_instance(id: 'i-00000001', cluster_tag: cluster_name, role_tag: 'db') }
        let (:instance_2) { stub_instance(id: 'i-00000002', cluster_tag: cluster_name, role_tag: 'db') }
        let (:instance_3) { stub_instance(id: 'i-00000003', cluster_tag: cluster_name, role_tag: 'db') }

        include_examples('running cluster with roles', [:db])
        include_examples('cluster with instance in role', :db, 0, 'i-00000001')
        include_examples('cluster with instance in role', :db, 1, 'i-00000002')
        include_examples('cluster with instance in role', :db, 2, 'i-00000003')
      end

      context 'all in this cluster with different roles' do
        let (:instance_1) { stub_instance(id: 'i-00000001', cluster_tag: cluster_name, role_tag: 'db') }
        let (:instance_2) { stub_instance(id: 'i-00000002', cluster_tag: cluster_name, role_tag: 'app') }
        let (:instance_3) { stub_instance(id: 'i-00000003', cluster_tag: cluster_name, role_tag: 'cache') }

        include_examples('running cluster with roles', [:db, :app, :cache])
        include_examples('cluster with instance in role', :db, 0, 'i-00000001')
        include_examples('cluster with instance in role', :app, 0, 'i-00000002')
        include_examples('cluster with instance in role', :cache, 0, 'i-00000003')
      end
    end
  end

  def stub_describe_instances(*reservations)
    client.stub_responses(:describe_instances, reservations: reservations)
  end

  def stub_reservation(*instances)
    { instances: instances }
  end

  def stub_instance(args = {})
    id       = args[:id] || 'i-00000001'
    instance = {
        instance_id:        id,
        public_ip_address:  args[:public_ip] || public_ip(id), #46.137.0.1',
        private_ip_address: args[:private_ip] || private_ip(id), #'10.248.0.1',
        public_dns_name:    args[:public_dns] || public_dns(id), #'ec2-46-137-0-1.eu-west-1.compute.amazonaws.com',
        private_dns_name:   args[:public_dns] || private_dns(id), #'ip-10-248-0-1.eu-west-1.compute.internal',
        tags:               []
    }
    (args[:tags] || {}).each do |key, value|
      instance[:tags] << { key: key, value: value }
    end

    if args[:cluster_tag]
      instance[:tags] << { key: 'cloudfinder-cluster', value: args[:cluster_tag] }
    end

    if args[:role_tag]
      instance[:tags] << { key: 'cloudfinder-role', value: args[:role_tag] }
    end

    instance
  end

  def numeric_instance_id(instance_id)
    instance_id[-2, 2].to_i
  end

  def private_ip(instance_id)
    "10.248.0.#{numeric_instance_id(instance_id)}"
  end

  def public_ip(instance_id)
    "46.137.0.#{numeric_instance_id(instance_id)}"
  end

  def private_dns(instance_id)
    "ec2-46-137-0-#{numeric_instance_id(instance_id)}.eu-west-1.compute.amazonaws.com"
  end

  def public_dns(instance_id)
    "ip-10-248-0-#{numeric_instance_id(instance_id)}.eu-west-1.compute.internal"
  end

end
