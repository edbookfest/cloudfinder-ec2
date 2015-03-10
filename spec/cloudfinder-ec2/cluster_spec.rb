describe Cloudfinder::EC2::Cluster do
  let (:cluster_name) { 'production' }
  let (:instances) { [] }
  subject { Cloudfinder::EC2::Cluster.new(cluster_name: cluster_name, instances: instances) }

  shared_examples_for 'cluster' do
    it 'should have cluster name' do
      expect(subject.cluster_name).to eq(cluster_name)
    end

    it 'should include cluster name in hash representation' do
      expect(subject.to_hash[:cluster_name]).to eq cluster_name
    end
  end

  shared_examples_for 'undefined role' do |rolename|
    it "should not have #{rolename} role" do
      expect(subject).not_to have_role(rolename)
    end

    it "should not have #{rolename} in hash representation" do
      expect(subject.to_hash[:roles]).not_to have_key rolename
    end

    it "should have empty instances for #{rolename} role" do
      expect(subject.list_role_instances(rolename)).to be_empty
    end
  end

  shared_examples_for 'undefined instance' do |unknown_instance_id|
    it 'should not have unknown instance' do
      expect(subject).not_to have_instance(unknown_instance_id)
    end

    it 'should throw when getting unknown instance'  do
      expect {subject.get_instance(unknown_instance_id)}.to raise_error(RangeError)
    end
  end

  shared_examples_for 'running instances' do |instance_ids|
    it 'should list array of all instances' do
      found_instances = subject.list_instances.map {|instance| instance.instance_id}
      expect(found_instances).to eq(instance_ids)
    end
  end

  shared_examples_for 'defined role with instances' do |role_name, instance_count|
    it "should have #{role_name} role" do
      expect(subject).to have_role(role_name)
    end

    it "should have #{role_name} in hash representation" do
      expect(subject.to_hash[:roles]).to have_key role_name
    end

    it "should have #{instance_count} elements for #{role_name} in hash representation" do
      expect(subject.to_hash[:roles][role_name].count).to eq instance_count
    end

    it "should list #{instance_count} instances for the #{role_name} role" do
      expect(subject.list_role_instances(role_name).count).to eq(instance_count)
    end
  end

  shared_examples_for 'running instance in role' do |role_name, instance_index, instance_id|
    it "should have the #{role_name}:##{instance_index} instance" do
      expect(subject).to have_instance(instance_id)
    end

    it "should get instance object for instance id #{instance_id}" do
      instance = subject.get_instance(instance_id)
      expect(instance).to be_a Cloudfinder::EC2::Instance
      expect(instance.instance_id).to eq instance_id
    end

    it "should return instance object for #{role_name}:##{instance_index}" do
      instance = subject.list_role_instances(role_name)[instance_index]
      expect(instance).to be_a Cloudfinder::EC2::Instance
      expect(instance.instance_id).to eq instance_id
    end

    it "should list the #{role_name}:##{instance_index} instance for the correct role" do
      listed_instance = subject.list_role_instances(role_name)[instance_index]
      expect(listed_instance.instance_id).to eq(instance_id)
    end

    it "should include #{role_name}:##{instance_index} in hash representation" do
      instance = subject.get_instance(instance_id)
      expect(subject.to_hash[:roles][role_name][instance_index]).to eq instance.to_hash
    end
  end

  context 'when created with no instances' do
    include_examples 'cluster'
    it { should be_empty }
    it { should_not be_running }

    include_examples('undefined role', :any)
    include_examples('undefined instance', 'i-0000001')

    it 'should have empty roles list' do
      expect(subject.list_roles).to be_empty
    end
  end

  context 'when created with single db instance' do
    let (:instances) { [
        stub_instance(:instance_id => 'i-0000001', :role => :db)
    ] }

    it { should_not be_empty }
    it { should be_running }
    include_examples 'cluster'
    include_examples('undefined role', :'any other')
    include_examples('undefined instance', 'i-0000002')
    include_examples('running instances', ['i-0000001'])
    include_examples('defined role with instances', :db, 1)
    include_examples('running instance in role', :db, 0, 'i-0000001')

    it 'should list the db role only' do
      expect(subject.list_roles).to eq([:db])
    end
  end

  context 'when created with multiple db instances' do
    let (:instances) { [
        stub_instance(:instance_id => 'i-0000001', :role => :db),
        stub_instance(:instance_id => 'i-0000002', :role => :db)
    ] }

    it { should_not be_empty }
    it { should be_running }
    include_examples 'cluster'
    include_examples('undefined role', :'any other')
    include_examples('undefined instance', 'i-0000003')
    include_examples('running instances', ['i-0000001', 'i-0000002'])
    include_examples('defined role with instances', :db, 2)
    include_examples('running instance in role', :db, 0, 'i-0000001')
    include_examples('running instance in role', :db, 1, 'i-0000002')

    it 'should list the db role only' do
      expect(subject.list_roles).to eq([:db])
    end
  end

  context 'when created with multiple db and app instances' do
    let (:instances) { [
        stub_instance(:instance_id => 'i-0000001', :role => :db),
        stub_instance(:instance_id => 'i-0000002', :role => :app),
        stub_instance(:instance_id => 'i-0000003', :role => :app)
    ] }

    it { should_not be_empty }
    it { should be_running }
    include_examples 'cluster'
    include_examples('undefined role', :'any other')
    include_examples('undefined instance', 'i-0000004')
    include_examples('running instances', ['i-0000001', 'i-0000002', 'i-0000003'])
    include_examples('defined role with instances', :db, 1)
    include_examples('defined role with instances', :app, 2)
    include_examples('running instance in role', :db, 0, 'i-0000001')
    include_examples('running instance in role', :app, 0, 'i-0000002')
    include_examples('running instance in role', :app, 1, 'i-0000003')

    it 'should list the db and app roles only' do
      expect(subject.list_roles).to eq([:db, :app])
    end
  end

  def stub_instance(data)
    Cloudfinder::EC2::Instance.new(data)
  end

end