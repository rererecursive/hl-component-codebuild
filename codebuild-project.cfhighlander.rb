CfhighlanderTemplate do
  Name 'codebuild-project'
  Description "codebuild-project - #{component_version}"

  Parameters do
    ComponentParam 'EnvironmentName', 'dev', isGlobal: true
    ComponentParam 'EnvironmentType', 'development', allowedValues: ['development','production'], isGlobal: true
  end


end
