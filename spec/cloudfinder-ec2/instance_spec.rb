describe Cloudfinder::EC2::Instance do
  let (:initial_data) { {
      :instance_id => 'i-12345678',
      :public_ip   => '123.123.123.123',
      :public_dns  => 'ec2-123-123-123-123.amazon.com',
      :private_ip  => '127.0.0.123',
      :private_dns => 'ec2-127-0-0-123.amazon.internal',
      :role        => :db
  }}

  subject { Cloudfinder::EC2::Instance.new(initial_data) }

  context "when created with valid data" do
    [:instance_id, :public_ip, :private_ip, :public_dns, :private_dns, :role].each do | attribute |
      it "should provide read-only access to #{attribute}" do
        expect(subject).to have_attributes(attribute => initial_data[attribute])
        expect { subject.method("#{attribute}=").call('foo') }.to raise_error(NameError)
      end

      it "should enforce immutability on #{attribute}" do
        value = subject.method("#{attribute}").call
        expect { value << 'foo' }.to raise_error
      end

      it "should include #{attribute} in hash representation" do
        expect(subject.to_hash[attribute]).to eq initial_data[attribute]
      end
    end
  end
end