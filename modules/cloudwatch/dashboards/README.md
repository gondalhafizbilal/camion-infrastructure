# CloudWatch Dashboards Module

This Terraform module creates comprehensive CloudWatch dashboards for monitoring AWS infrastructure components.

## Features

The module creates three specialized dashboards:

### 1. ECS Fargate Dashboard
- CPU and Memory utilization for each service
- Running, Pending, and Desired task counts
- Service-level monitoring across clusters

### 2. Database Dashboard
- **RDS Metrics:**
  - CPU Utilization
  - Database Connections
  - Freeable Memory
  - Free Storage Space
  - Read Latency
- **Redis/ElastiCache Metrics:**
  - CPU Utilization
  - Memory Usage Percentage
  - Current Connections
  - Cache Hit Rate
  - Network Bytes In

### 3. MWAA Dashboard
- Scheduler Heartbeat
- Tasks Running, Queued, Failed, and Successful
- Worker CPU and Memory Utilization
- DAG Processing Parse Time and Import Errors
- Scheduler CPU Utilization

## Usage

```hcl
module "cloudwatch_dashboards" {
  source = "../../../modules/cloudwatch-dashboards"

  environment = var.environment
  aws_region  = var.aws_region
  tags        = var.common_tags

  # ECS Services to monitor
  ecs_services = [
    {
      name         = "backend-service"
      cluster_name = "main-cluster"
    },
    {
      name         = "api-service"
      cluster_name = "main-cluster"
    }
  ]

  # RDS Instances to monitor
  rds_instances = [
    {
      identifier = "main-database"
    },
    {
      identifier = "analytics-database"
    }
  ]

  # Redis Clusters to monitor
  redis_clusters = [
    {
      cluster_id = "session-cache"
    },
    {
      cluster_id = "application-cache"
    }
  ]

  # MWAA Environments to monitor
  mwaa_environments = [
    {
      name = "data-pipeline-env"
    }
  ]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment name (e.g., dev, staging, prod) | `string` | n/a | yes |
| aws_region | AWS region for the dashboards | `string` | n/a | yes |
| tags | Tags to apply to all resources | `map(string)` | `{}` | no |
| ecs_services | List of ECS services to monitor | `list(object)` | `[]` | no |
| rds_instances | List of RDS instances to monitor | `list(object)` | `[]` | no |
| redis_clusters | List of Redis/ElastiCache clusters to monitor | `list(object)` | `[]` | no |
| mwaa_environments | List of MWAA environments to monitor | `list(object)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| ecs_dashboard_name | Name of the ECS Fargate dashboard |
| ecs_dashboard_url | URL of the ECS Fargate dashboard |
| database_dashboard_name | Name of the database dashboard |
| database_dashboard_url | URL of the database dashboard |
| mwaa_dashboard_name | Name of the MWAA dashboard |
| mwaa_dashboard_url | URL of the MWAA dashboard |

## Dashboard Widgets

Each dashboard is organized with logical widget placement:
- Time series charts for trend analysis
- Appropriate statistics (Average, Sum) based on metric type
- 5-minute periods for balanced detail and performance
- Consistent color schemes and layouts

## Notes

- All dashboards use a 5-minute period for metrics collection
- Widgets are arranged in a 24-unit wide grid for optimal viewing
- The module supports multiple services/instances per dashboard type
- Dashboard names are prefixed with the environment for easy identification