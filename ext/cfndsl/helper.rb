def load_file(filename, escape_new_lines=false)
  contents = File.open(File.join(Dir.pwd, filename))
  if escape_new_lines
    contents = contents.gsub("\n", "\\n")
  end
  return contents
end


def get_artifacts(config)
  artifacts = {
    Type: 'NO_ARTIFACTS'  # Default
  }

  if config.key?('artifacts')
    config['artifacts'] do |a|
      type = a['type']

      artifacts[:Type] = type
      artifacts[:ArtifactIdentifier] = a['identifier']
      artifacts[:OverrideArtifactName] = a['override_artifact_name']

      if type == 'S3'
        artifacts[:EncryptionDisabled] = a['encryption_disabled']
        artifacts[:Location] = a['location']
        artifacts[:Name] = a['name']
        artifacts[:NamespaceType] = a['namespace_type']
        artifacts[:Packaging] = a['packaging']
        artifacts[:Path] = a['path']
      end
    end
  end

  return artifacts.delete_if { |k,v| v.nil? }
end


def get_cache(config)
  cache = { Type: 'NO_CACHE' }

  if !config.key?('cache')
    return cache
  end

  config['cache'] do |c|
    type = c['type']

    if type == 'S3'
      cache[:Location] = c['location']
    elsif type == 'LOCAL'
      cache[:Modes] = c['modes']
    end

    cache[:Type] = type
  end

  return cache.delete_if { |k,v| v.nil? }
end


def get_environment(config)
  env = config['environment']

  environment = {
    Certificate:              env['certificate'],
    ComputeType:              env['compute_type'],
    Image:                    env['image'],
    ImagePullCredentialsType: env['image_creds_type'],
    PrivilegedMode:           env['privileged'],
    Type:                     env['type']
  }

  if env['registry_creds']
    environment[:RegistryCredential] = {
      Credential: env['registry_creds']['credential'],
      provider:   env['registry_creds']['provider']
    }
  end

  variables = []
  env['variables'].each do |item|
    var = {
      Name: item['name'],
      Value: item['value']
    }
    var[:Type] = item['type'] if item['type']
    variables << var
  end

  environment[:EnvironmentVariables] = variables

  return environment.delete_if { |k,v| v.nil? || !v }
end


def get_logs_config(config)
  cfg = {}
  logs = config['logs']

  if logs['s3']
    cfg = {
      S3Logs: {
        Status: logs['s3']['status']
      }
    }
    cfg[:S3Logs][:Location] = logs['s3']['location'] if logs['s3']['location']
  elsif logs['cloudwatch']
    cfg = {
      CloudWatchLogs: {
        Status: logs['cloudwatch']['status']
      }
    }
    cfg[:CloudWatchLogs][:GroupName] = logs['cloudwatch']['group'] if logs['cloudwatch']['group']
    cfg[:CloudWatchLogs][:StreamName] = logs['cloudwatch']['stream'] if logs['cloudwatch']['stream']
  end

  return cfg
end


def get_name(project_name)
  return FnSub("${AWS::StackName}-#{project_name}")
end


def get_secondary_artifacts(config)
  secondary_artifacts = config['secondary_artifacts']
  artifacts = []

  secondary_artifacts.each do |artifact|
    artifacts << get_artifacts({'artifacts': artifact})
  end

  return artifacts
end


def get_secondary_sources(config, project_name)
  secondary_sources = config['get_secondary_sources']
  sources = []

  secondary_sources.each do |source|
    source << get_source(source, project_name)
  end

  return sources
end


def get_source(config, project_name)
  cfg = config['source']
  type = cfg['type']

  source = {
    GitCloneDepth:      cfg['git_clone_depth'],
    InsecureSsl:        cfg['insecure_ssl'],
    Location:           (cfg['location'] if type != 'CODEPIPELINE'),
    ReportBuildStatus:  cfg['report_build_status'],
    SourceIdentifier:   "#{project_name}_source".gsub("-", "_"),
    Type:               type
  }

  if type.start_with?('GITHUB')
    source[:Auth] = {
      Resource: cfg['auth']['resource'],
      Type:     'OAUTH'
    }
  end

  if cfg['buildspec']
    file = cfg['buildspec']['file'] || 'buildspec.yml'

    if cfg['buildspec']['inline']
      source[:BuildSpec] = File.read(File.join(Dir.pwd, "#{file}"))
    else
      source[:BuildSpec] = file
    end
  end

  return source.delete_if { |k,v| v.nil? }

end

def get_tags(config)
  tags = config['tags']
  new_tags = []

  tags.each do |k,v|
    new_tags << {
      Key: k,
      Value: v
    }
  end

  return new_tags
end


def get_triggers(config)
  triggers = config['triggers']
  ts = {
    Webhook: triggers['webhook'],
    FilterGroups: []
  }

  triggers['filters'].each do |f|
    filter = {
      Pattern: f['pattern'],
      Type: f['type']
    }

    filter[:ExcludeMatchedPattern] = f['exclude_pattern'] if f['exclude_pattern']
    ts[:FilterGroups] << [filter]
  end
end


def get_policies(config)
  policies = []

  config['policies'].each do |policy, config|
    policies << iam_policy_allow(policy, config['action'], config['resource'] || '*')
  end if config['policies']

  return policies
end


def get_vpc_config(config)
  cfg = config['vpc_config']
  vpc = {
    SecurityGroupIds: [],
    Subnets: [],
    VpcId: nil
  }

  cfg['security_groups'].each do |group|
    vpc[:SecurityGroupIds] << group
  end if cfg['security_groups']

  cfg['subnets'].each do |subnet|
    vpc[:Subnets] << subnet
  end if cfg['subnets']

  vpc[:VpcId] = cfg['vpc'] if cfg['vpc']

  return vpc.delete_if { |k,v| v.nil? || !v }
end
