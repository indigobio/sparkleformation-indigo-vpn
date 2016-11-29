SfnRegistry.register(:modify_route53) do
  { 'Action' => %w(route53:ChangeResourceRecordSets
                   route53:ChangeTagsForResource
                   route53:Get*
                   route53:List*),
    'Resource' => %w( * ),
    'Effect' => 'Allow'
  }
end

