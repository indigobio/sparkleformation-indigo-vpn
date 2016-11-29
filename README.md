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
| AllowSSHFrom | 127.0.0.1/32 | CIDR block from which to allow SSH to the VPN server.  Not necessary unless debugging. |
| ChefRunlist | role[base],role[openvpn_as] | No need to change |
| ChefServer | https://api.opscode.com/organizations/product_dev | No need to change |
| ChefValidationClientName | product_dev-validator | No need to change |
| ChefVersion | 12.4.0 | No need to change |
| RootVolumeSize | 12 | No need to change |
| SshKeyPair | indigo-bootstrap | No need to change |
| Vpc | auto-determined | No need to change |
| VpnAssociatePublicIpAddress | true | No need to change |
| VpnDesiredCapacity | 1 | No need to change |
| VpnInstanceMonitoring | false | Set to true to enable detailed cloudwatch monitoring (additional costs incurred) |
| VpnInstanceType | t2.small | Increase the instance size for more network throughput |
| VpnMaxSize | 1 | No need to change |
| VpnMinSize | 0 | No need to change |
| VpnNotificationTopic | auto-determined | No need to change |
