ENV['sg']                 ||= 'vpn_sg'
ENV['run_list']           ||= 'role[base],role[openvpn_as]'
ENV['notification_topic'] ||= "#{ENV['org']}-#{ENV['environment']}-deregister-chef-node"

SparkleFormation.new(:vpn, :provider => :aws).load(:base, :ssh_key_pair, :trusty_ami).overrides do
  description <<"EOF"
OpenVPN EC2 instance, configured by Chef.  Route53 record: vpn.#{ENV['public_domain']}.
EOF

  parameters(:vpc) do
    type 'String'
    default registry!(:my_vpc)
    allowed_values array!(registry!(:my_vpc))
  end

  parameters(:allow_ssh_from) do
    type 'String'
    allowed_pattern "(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})/(\\d{1,2})"
    default '127.0.0.1/32'
    description 'Network to allow SSH from, to NAT instances. Note that the default of 127.0.0.1/32 effectively disables SSH access.'
    constraint_description 'Must follow IP/mask notation (e.g. 192.168.1.0/24)'
  end

  dynamic!(:vpc_security_group, 'vpn',
           :ingress_rules =>
             [
               { :cidr_ip => '0.0.0.0/0', :ip_protocol => 'udp', :from_port => '1194', :to_port => '1194' },
               { :cidr_ip => ref!(:allow_ssh_from), :ip_protocol => 'tcp', :from_port => '22', :to_port => '22' }
             ]
          )

  dynamic!(:security_group_ingress, 'private-to-nat-all',
           :source_sg => registry!(:my_security_group_id, 'private_sg'),
           :ip_protocol => '-1',
           :from_port => '-1',
           :to_port => '-1',
           :target_sg => attr!(:vpn_ec2_security_group, 'GroupId')
          )

  dynamic!(:security_group_ingress, 'nat-to-private-all',
           :source_sg => attr!(:vpn_ec2_security_group, 'GroupId'),
           :ip_protocol => '-1',
           :from_port => '-1',
           :to_port => '-1',
           :target_sg => registry!(:my_security_group_id, 'private_sg')
          )

  dynamic!(:iam_instance_profile, 'vpn',
           :policy_statements => [ :modify_route53 ],
           :chef_bucket => registry!(:my_s3_bucket, 'chef')
          )

  dynamic!(:launch_config, 'vpn',
           :iam_instance_profile => 'VpnIAMInstanceProfile',
           :iam_role => 'VpnIAMRole',
           :public_ips => 'true',
           :chef_run_list => ENV['run_list'],
           :security_groups => _array(ref!(:vpn_ec2_security_group)),
          )

  dynamic!(:auto_scaling_group, 'vpn',
           :min_size => 0,
           :desired_capacity => 1,
           :max_size => 1,
           :launch_config => :vpn_auto_scaling_launch_configuration,
           :subnet_ids => registry!(:my_public_subnet_ids),
           :notification_topic => registry!(:my_sns_topics, ENV['notification_topic'])
          )
end
