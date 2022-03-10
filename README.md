# ABANDONED PROJECT
** This package is abandoned and will not be maintained. It was working (though not recently updated) as at 9th March 2022). **

# Cloudfinder::EC2

[![Build Status](https://travis-ci.org/edbookfest/cloudfinder-ec2.png)](https://travis-ci.org/edbookfest/cloudfinder-ec2)
[![Coverage Status](https://coveralls.io/repos/edbookfest/cloudfinder-ec2/badge.png?branch=master)](https://coveralls.io/r/edbookfest/cloudfinder-ec2)
[![Gem Version](https://badge.fury.io/rb/cloudfinder-ec2.png)](http://badge.fury.io/rb/cloudfinder-ec2)
[![Code Climate](https://codeclimate.com/github/edbookfest/cloudfinder-ec2.png)](https://codeclimate.com/github/edbookfest/cloudfinder-ec2)
[![Dependency Status](https://gemnasium.com/edbookfest/cloudfinder-ec2.png)](https://gemnasium.com/edbookfest/cloudfinder-ec2)

Uses EC2 instance tags to locate all the running instances in a given cluster, grouped by role.

## Tagging your instances

An instance can belong to a single cluster, with a single role. These are identified based on two EC2 tags with the
keys `cloudfinder-cluster` and the `cloudfinder-role`. Add the tags to your instances using the AWS API, command line
tools, console, or as part of an auto-scaling-group launch configuration.

## API credentials

cloudfinder-ec2 needs access to a set of AWS credentials with read-only access to your EC2 instances. When running
on EC2, the best way to provide this is with an instance IAM role. Local AWS credentials files and environment
variables are also supported. For further information on credential management see the
[aws-sdk documentation](http://docs.aws.amazon.com/sdkforruby/api/index.html#Credentials)

## Cluster detection

By default, cloudfinder-ec2 will query the EC2 instance metadata API to attempt to detect the name and EC2 region
of the cluster containing the running instance.

If you are running outside EC2, or want to load details of a different cluster (for example if you are running
the command on an EC2 server that is not part of the cluster you're interested in) you can specify the cluster
name and region to load.

If you do not provide a cluster name and region, and you are not on EC2, then the command will fail.

## Usage

### As a shell command

Install the cloudfinder-ec2 binary by adding the gem to your system in the usual way
(`gem install cloudfinder-ec2`).

Running `cloudfinder-ec2 list` will output a JSON hash of the running cluster, grouped by role, which
looks something like this:

```json
{
  "cluster_name": "production",
  "roles": {
    "loadbalancer": [
      {
        "instance_id": "i-00000001",
        "public_ip": "46.137.96.1",
        "public_dns": "ec2-46-137-96-1.eu-west-1.compute.amazonaws.com",
        "private_dns": "ip-10-248-183-1.eu-west-1.compute.internal",
        "private_ip": "10.248.183.1",
        "role": "loadbalancer"
      }
    ],
    "app-server": [
      {
        "instance_id": "i-00000002",
        "public_ip": "54.74.200.2",
        "public_dns": "ec2-54-74-200-2.eu-west-1.compute.amazonaws.com",
        "private_dns": "ip-10-56-18-2.eu-west-1.compute.internal",
        "private_ip": "10.56.18.2",
        "role": "app-server"
      },
      {
        "instance_id": "i-00000003",
        "public_ip": "54.74.200.3",
        "public_dns": "ec2-54-74-200-3.eu-west-1.compute.amazonaws.com",
        "private_dns": "ip-10-56-18-3.eu-west-1.compute.internal",
        "private_ip": "10.56.18.3",
        "role": "app-server"
      }
    ],
    "db-server": [
      {
        "instance_id": "i-00000004",
        "public_ip": "54.220.216.4",
        "public_dns": "ec2-54-220-216-4.eu-west-1.compute.amazonaws.com",
        "private_dns": "ip-10-86-141-4.eu-west-1.compute.internal",
        "private_ip": "10.86.141.4",
        "role": "db-server"
      }
    ]
  }
}
```

This output is designed to be piped to a file or captured by any other process that needs information about
the composition of a given cluster.

### As a library

You can also use cloudfinder-ec2 as a gem within your ruby application. Add it to your project's Gemfile, and
then:

```ruby
require 'cloudfinder-ec2'
cluster = Cloudfinder::EC2::Clusterfinder.new.find(cluster_name: 'production', region: 'eu-west-1)
# returns a Cloudfinder::EC2::Cluster instance with useful methods to interact with your cluster

if cluster.running?
  puts cluster.list_roles
  puts cluster.has_role?(:db)
  puts cluster.list_role_instances(:db)
end
```

You can also autodetect the cluster if required. This will throw an exception if the instance metadata is
not available (eg because you are not on an EC2 instance).

```ruby
require 'cloudfinder-ec2'
puts Cloudfinder::EC2::Clusterfinder.new.detect_cluster # {cluster_name: 'production', region: 'eu-west-1'}
```

### Within a chef recipe

```ruby
chef_gem 'cloudfinder-ec2'
require 'cloudfinder-ec2'
# and use as a library as above
```

## Limitations

* Exceptions raised by the instance metadata service and/or AWS API are allowed to bubble, there is no
  retry or recovery within the library.
* Currently we only fetch a single page of results from the AWS API. If you have more instances that fit
  in a single describe instances call, you probably need a more sophisticated cluster discovery tool
* We only search for cluster instances in a single AWS region - again if you have multi-region clusters
  you may be better with a more sophisticated tool

## Copyright

Copyright (c) 2015 Edinburgh International Book Festival Ltd. See LICENSE.txt for further details.
