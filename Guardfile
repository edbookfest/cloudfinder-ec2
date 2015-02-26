guard 'rspec' do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/cloudfinder-ec2/(.+)\.rb$})     { |m| "spec/cloudfinder-ec2/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec" }
end