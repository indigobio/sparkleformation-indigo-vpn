## sparkleformation-indigo-vpn
This repository contains a SparkleFormation template that creates a VPN
EC2 instance, and its associated security groups and ingress rules.

SparkleFormation is a tool that creates CloudFormation templates, which are
static documents declaring resources for AWS to create.

The network, spanning a /16 CIDR allocation in the 172.16.0.0/12 IP address
range, consists of a public and private subnet for every availability zone
that we have access to in any given AWS region.  

Additionally, the template creates a public Route53 (DNS) CNAME record:
vpn.`ENV['public_domain']`.

### Dependencies

The template requires external Sparkle Pack gems, which are noted in
the Gemfile and the .sfn file.  These gems interact with AWS through the
`aws-sdk-core` gem to identify or create  availability zones, subnets, and 
security groups.

### Parameters

When launching the compiled CloudFormation template, you will be prompted for
some stack parameters:

| Parameter | Default Value | Purpose |
|-----------|---------------|---------|
| Write     | stuff         | here    |
