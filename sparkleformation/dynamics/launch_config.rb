SparkleFormation.dynamic(:launch_config) do |_name, _config = {}|

  _config[:ami_map]              ||= :region_to_ami
  _config[:iam_instance_profile] ||= "#{_name}_i_a_m_instance_profile".to_sym
  _config[:iam_role]             ||= "#{_name}_i_a_m_role".to_sym
  _config[:chef_run_list]        ||= 'role[base]'
  _config[:chef_version]         ||= '12.4.0'
  _config[:extra_bootstrap]      ||= nil # a registry, if defined.  Make sure to add newlines as '\n'.

  parameters("#{_name}_instance_type".to_sym) do
    type 'String'
    allowed_values registry!(:ec2_instance_types)
    default _config[:instance_type] || 't2.small'
  end

  parameters("#{_name}_instance_monitoring".to_sym) do
    type 'String'
    allowed_values %w(true false)
    default _config.fetch(:monitoring, 'false').to_s
    description 'Enable detailed cloudwatch monitoring for each instance'
  end

  parameters("#{_name}_associate_public_ip_address".to_sym)do
    type 'String'
    allowed_values %w(true false)
    default _config.fetch(:public_ips, 'false').to_s
    description 'Associate public IP addresses to instances'
  end

  parameters(:chef_run_list) do
    type 'CommaDelimitedList'
    default _config[:chef_run_list]
    description 'The run list to run when Chef client is invoked'
  end

  parameters(:chef_validation_client_name) do
    type 'String'
    allowed_pattern "[\\x20-\\x7E]*"
    default _config[:chef_validation_client_name] || 'product_dev-validator'
    description 'Chef validation client name; see https://docs.chef.io/chef_private_keys.html'
    constraint_description 'can only contain ASCII characters'
  end

  parameters(:chef_server) do
    type 'String'
    allowed_pattern "[\\x20-\\x7E]*"
    constraint_description 'can only contain ASCII characters'
    default _config[:chef_server] || 'https://api.opscode.com/organizations/product_dev'
  end

  parameters(:chef_version) do
    type 'String'
    allowed_pattern "[\\x20-\\x7E]*"
    constraint_description 'can only contain ASCII characters'
    default _config[:chef_version] || 'latest'
  end

  parameters(:root_volume_size) do
    type 'Number'
    min_value '1'
    max_value '1000'
    default _config[:root_volume_size] || '12'
    description 'The size of the root volume (/dev/sda1) in gigabytes'
  end

  if _config.fetch(:create_ebs_volumes, false)
    conditions.set!(
        "#{_name}_volumes_are_io1".to_sym,
        equals!(ref!("#{_name}_ebs_volume_type".to_sym), 'io1')
    )

    parameters("#{_name}_ebs_volume_size".to_sym) do
      type 'Number'
      min_value '1'
      max_value '1000'
      default _config[:volume_size] || '100'
    end

    parameters("#{_name}_ebs_volume_type".to_sym) do
      type 'String'
      allowed_values _array('standard', 'gp2', 'io1')
      default _config[:volume_type] || 'gp2'
      description 'Magnetic (standard), General Purpose (gp2), or Provisioned IOPS (io1)'
    end

    parameters("#{_name}_ebs_provisioned_iops".to_sym) do
      type 'Number'
      min_value '1'
      max_value '4000'
      default _config[:piops] || '300'
    end

    parameters("#{_name}_delete_ebs_volume_on_termination".to_sym) do
      type 'String'
      allowed_values ['true', 'false']
      default _config[:del_on_term] || 'true'
    end

    parameters("#{_name}_ebs_optimized".to_sym) do
      type 'String'
      allowed_values _array('true', 'false')
      default _config[:ebs_optimized] || 'false'
      description 'Create an EBS-optimized instance (additional charges apply)'
    end
  end

  dynamic!(:auto_scaling_launch_configuration, _name).properties do
    image_id map!(_config[:ami_map], ref!('AWS::Region'), :ami)
    instance_type ref!("#{_name}_instance_type".to_sym)
    instance_monitoring ref!("#{_name}_instance_monitoring".to_sym)
    iam_instance_profile ref!(_config[:iam_instance_profile])
    associate_public_ip_address ref!("#{_name}_associate_public_ip_address".to_sym)
    key_name ref!(:ssh_key_pair)
    security_groups _config[:security_groups]
    registry!(:ebs_volumes)
    user_data registry!(:user_data, _name,
                        :iam_role => ref!(_config[:iam_role]),
                        :launch_config => "#{_name.capitalize}AutoScalingLaunchConfiguration",
                        :resource_id => "#{_name.capitalize}AutoScalingAutoScalingGroup")
  end

  dynamic!(:auto_scaling_launch_configuration, _name).registry!(:chef_client, _name,
           :chef_bucket => registry!(:my_s3_bucket, 'chef'),
           :chef_server => ref!(:chef_server),
           :chef_version => ref!(:chef_version),
           :chef_run_list => ref!(:chef_run_list),
           :iam_role => ref!(_config[:iam_role]),
           :chef_validation_client => ref!(:chef_validation_client_name),
           :chef_data_bag_secret =>  true
          )

  dynamic!(:auto_scaling_launch_configuration, _name).depends_on "#{_name.capitalize}IAMInstanceProfile"
end
