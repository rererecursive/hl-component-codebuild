CloudFormation do



  AWSTemplateFormatVersion "2010-09-09"
  Description "#{component_name} - #{component_version}"

  project.each do |project_name, config|

    Resource("#{project_name}Project") {
      Type 'AWS::CodeBuild::Project'

      Property('Artifacts',     get_artifacts(config))
      Property('BadgeEnabled',  config['badge_enabled'])  if config.key?('badge_enabled')
      Property('Cache',         get_cache(config))
      Property('Description',   config['description'])    if config.key?('description')
      Property('EncryptionKey', config['encryption_key']) if config.key?('encryption_key')
      Property('Environment',   get_environment(config))
      Property('LogsConfig',    get_logs_config(config))  if config.key?('logs')
      Property('Name',          get_name(project_name))
      Property('QueuedTimeoutInMinutes',  config['queued_timeout']) if config.key?('queued_timeout')
      Property('SecondaryArtifacts',      get_secondary_artifacts(config)) if config.key?('secondary_artifacts')
      Property('SecondarySources',        get_secondary_sources(config, project_name)) if config.key?('secondary_sources')
      Property('ServiceRole',   Ref("#{project_name}ServiceRole"))
      Property('Source',        get_source(config, project_name))
      Property('Tags',          get_tags(config))         if config.key?('tags')
      Property('TimeoutInMinutes', 30)
      Property('Triggers',      get_triggers(config))     if config.key?('triggers')
      Property('VpcConfig',     get_vpc_config(config))   if config.key?('vpc_config')
    }

    Resource("#{project_name}ServiceRole") {
      Type 'AWS::IAM::Role'
      Property('AssumeRolePolicyDocument', {
        Statement: [
          Effect: 'Allow',
          Principal: { Service: ['codebuild.amazonaws.com'] },
          Action: ['sts:AssumeRole']
        ]
      })
      Property('Path', '/')
      Property('Policies', get_policies(config)) if config.key?('policies')
    }
  end

end

