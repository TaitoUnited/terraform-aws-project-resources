# AWS project resources

Provides AWS resources typically required by projects. The resources are defined in a cloud provider agnostic and developer friendly YAML format. An example:

```
stack:
  uptimeEnabled: true
  backupEnabled: true

  ingress:
    enabled: true
    class: cloudfront
    createMainDomain: false
    domains:
      - name: myproject.mydomain.com
        altDomains:
          - name: www.myproject.mydomain.com

  services:
    admin:
      type: static
      path: /admin
      uptimePath: /admin

    client:
      type: static
      path: /
      uptimePath: /

    server:
      type: function
      path: /api
      uptimePath: /api/uptimez
      timeout: 3
      runtime: nodejs12.x
      memoryRequest: 128
      secrets:
        DATABASE_PASSWORD: my-project-prod-app
        REDIS_PASSWORD: ${taito_project}-${taito_env}-redis.secretKey
      env:
        TOPIC_JOBS: my-project-prod-jobs
        DATABASE_HOST: my-postgres.c45t0ln04uqh.us-east-1.rds.amazonaws.com
        DATABASE_PORT: 5432
        DATABASE_SSL_ENABLED: true
        DATABASE_NAME: my-project-prod
        DATABASE_USER: my-project-prod-app
        DATABASE_POOL_MIN: 5
        DATABASE_POOL_MAX: 10
        REDIS_HOST: my-project-prod-001.my-project-prod.nde1c2.use1.cache.amazonaws.com
        REDIS_PORT: 6379
        S3_BUCKET: my-project-prod
        S3_REGION: us-east-1
      # Example: Allow bucket/topic access with awsPolicy instead of service account
      awsPolicy:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Action:
              - s3:GetObject
              - s3:PutObject
              - s3:PutObjectAcl
            Resource: 'arn:aws:s3:::my-project-prod/*'
          - Effect: Allow
            Action:
              - sns:Publish
            Resource: 'arn:aws:sns:::my-project-prod-jobs'

    jobs:
      type: topic
      name: my-project-prod-jobs
      subscribers:
        - id: my-project-prod-worker

    worker:
      type: container # TODO: implement
      image: my-registry/my-worker:1234
      replicas: 2
      memoryRequest: 128
      secrets:
        # Example: Allow bucket/topic access with service account instead of awsPolicy
        SERVICE_ACCOUNT_KEY: my-project-prod-worker-serviceaccount.key
      env:
        TOPIC_JOBS: my-project-prod-jobs
        S3_BUCKET: my-project-prod
        S3_REGION: us-east-1

    redis:
      type: redis
      name: my-project-prod
      replicas: 2
      machineType: cache.t2.small
      zones:
        - us-east1a
        - us-east1b
      secret: my-project-prod-redis.secretKey

    bucket:
      type: bucket
      name: my-bucket-prod
      location: us-east-1
      storageClass: STANDARD_IA
      corsRules:
        - allowedOrigins:
          - https://myproject.mydomain.com
          - https://www.myproject.mydomain.com
      queues: # TODO: implement
        - name: my-bucket-prod
          events:
            - s3:ObjectCreated:Put
            - s3:ObjectRemoved:Delete
      # Object lifecycle
      versioning: true
      versioningRetainDays: 60
      lockRetainDays: # TODO: implement
      transitionRetainDays:
      transitionStorageClass:
      autoDeletionRetainDays:
      # Replication (TODO: implement)
      replicationBucket:
      # Backup (TODO: implement)
      backupRetainDays: 60
      backupLocation: us-west-1
      backupLock: true
      # User rights
      admins:
        - id: john.doe
      objectAdmins:
        - id: jane.doe
        - id: my-project-prod-worker
      objectViewers:
        - id: jack.doe

  serviceAccounts:
    - id: my-project-prod-worker

```

With `create_*` variables you can choose which resources are created/updated in which phase. For example, you can choose to update some of the resources manually when the environment is created or updated:

```
  create_domain                       = true
  create_domain_certificate           = true
  create_storage_buckets              = true
  create_databases                    = true
  create_in_memory_databases          = true
  create_topics                       = true
  create_service_accounts             = true
  create_uptime_checks                = true
  create_container_image_repositories = true
```

And choose to update gateway, containers, and functions on every deployment in your CI/CD pipeline:

```
  create_ingress                      = true
  create_containers                   = true
  create_functions                    = true
  create_function_permissions         = true
```

Similar YAML format is used also by the following modules:

- [AWS project resources](https://registry.terraform.io/modules/TaitoUnited/project-resources/aws)
- [Azure project resources](https://registry.terraform.io/modules/TaitoUnited/project-resources/azurerm)
- [Google Cloud project resources](https://registry.terraform.io/modules/TaitoUnited/project-resources/google)
- [Digital Ocean project resources](https://registry.terraform.io/modules/TaitoUnited/project-resources/digitalocean)
- [Full-stack template (Helm chart for Kubernetes)](https://github.com/TaitoUnited/taito-charts/tree/master/full-stack)

NOTE: This module creates resources for only one project environment. That is, such resources should already exist that are shared among multiple projects or project environments (e.g. users, roles, vpc networks, kubernetes, database clusters). You can use the following modules to create the shared infrastructure:

- [Admin](https://registry.terraform.io/modules/TaitoUnited/admin/aws)
- [DNS](https://registry.terraform.io/modules/TaitoUnited/dns/aws)
- [Network](https://registry.terraform.io/modules/TaitoUnited/network/aws)
- [Compute](https://registry.terraform.io/modules/TaitoUnited/compute/aws)
- [Kubernetes](https://registry.terraform.io/modules/TaitoUnited/kubernetes/aws)
- [Databases](https://registry.terraform.io/modules/TaitoUnited/databases/aws)
- [Storage](https://registry.terraform.io/modules/TaitoUnited/storage/aws)
- [Monitoring](https://registry.terraform.io/modules/TaitoUnited/monitoring/aws)
- [Integrations](https://registry.terraform.io/modules/TaitoUnited/integrations/aws)
- [PostgreSQL privileges](https://registry.terraform.io/modules/TaitoUnited/privileges/postgresql)
- [MySQL privileges](https://registry.terraform.io/modules/TaitoUnited/privileges/mysql)

> TIP: This module is used by [project templates](https://taitounited.github.io/taito-cli/templates/#project-templates) of [Taito CLI](https://taitounited.github.io/taito-cli/). See the [full-stack-template](https://github.com/TaitoUnited/full-stack-template) as an example on how to use this module.

Contributions are welcome! This module should include implementations for the most commonly used AWS services. For more specific cases, the YAML can be extended with additional Terraform modules.
