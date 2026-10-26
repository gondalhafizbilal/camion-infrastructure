# ECS Fargate Workloads Dashboard
resource "aws_cloudwatch_dashboard" "ecs_fargate" {
  dashboard_name = "${var.environment}-ecs-fargate-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            for service in var.ecs_services : [
              "AWS/ECS", "CPUUtilization", "ServiceName", service.name, "ClusterName", service.cluster_name
            ]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "ECS Service CPU Utilization"
          period  = 300
          stat    = "Average"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            for service in var.ecs_services : [
              "AWS/ECS", "MemoryUtilization", "ServiceName", service.name, "ClusterName", service.cluster_name
            ]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "ECS Service Memory Utilization"
          period  = 300
          stat    = "Average"
        }
      }
    ]
  })

}
# Database Dashboard (RDS and Redis)
resource "aws_cloudwatch_dashboard" "database" {
  dashboard_name = "${var.environment}-database-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # RDS Metrics
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            for db in var.rds_instances : [
              "AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", db.identifier
            ]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "RDS CPU Utilization"
          period  = 300
          stat    = "Average"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            for db in var.rds_instances : [
              "AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", db.identifier
            ]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "RDS Database Connections"
          period  = 300
          stat    = "Average"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 8
        height = 6

        properties = {
          metrics = [
            for db in var.rds_instances : [
              "AWS/RDS", "FreeableMemory", "DBInstanceIdentifier", db.identifier
            ]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "RDS Freeable Memory"
          period  = 300
          stat    = "Average"
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 6
        width  = 8
        height = 6

        properties = {
          metrics = [
            for db in var.rds_instances : [
              "AWS/RDS", "ReadLatency", "DBInstanceIdentifier", db.identifier
            ]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "RDS Read Latency"
          period  = 300
          stat    = "Average"
        }
      },
      # Redis/ElastiCache Metrics
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6

        properties = {
          metrics = [
            for redis in var.redis_clusters : [
              "AWS/ElastiCache", "CPUUtilization", "CacheClusterId", "${redis.cluster_id}-001"
            ]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Redis CPU Utilization"
          period  = 300
          stat    = "Average"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6

        properties = {
          metrics = [
            for redis in var.redis_clusters : [
              "AWS/ElastiCache", "DatabaseMemoryUsagePercentage", "CacheClusterId", "${redis.cluster_id}-001"
            ]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Redis Memory Usage"
          period  = 300
          stat    = "Average"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 18
        width  = 8
        height = 6

        properties = {
          metrics = [
            for redis in var.redis_clusters : [
              "AWS/ElastiCache", "CurrConnections", "CacheClusterId", "${redis.cluster_id}-001"
            ]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Redis Current Connections"
          period  = 300
          stat    = "Average"
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 18
        width  = 8
        height = 6

        properties = {
          metrics = [
            for redis in var.redis_clusters : [
              "AWS/ElastiCache", "CacheHitRate", "CacheClusterId", "${redis.cluster_id}-001"
            ]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Redis Cache Hit Rate"
          period  = 300
          stat    = "Average"
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 18
        width  = 8
        height = 6

        properties = {
          metrics = [
            for redis in var.redis_clusters : [
              "AWS/ElastiCache", "NetworkBytesIn", "CacheClusterId", "${redis.cluster_id}-001"
            ]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Redis Network Bytes In"
          period  = 300
          stat    = "Sum"
        }
      }
    ]
  })

}
# MWAA (Managed Workflows for Apache Airflow) Dashboard
resource "aws_cloudwatch_dashboard" "mwaa" {
  dashboard_name = "${var.environment}-mwaa-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            for env in var.mwaa_environments : [
              "AmazonMWAA", "SchedulerHeartbeat", "Function", "Scheduler", "Environment", env.name
            ]
          ]
          view    = "timeSeries"
          stacked = true
          region  = var.aws_region
          title   = "MWAA Scheduler Heartbeat"
          period  = 300
          stat    = "Average"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            for env in var.mwaa_environments : [
              "AWS/MWAA", "RunningTasks", "Environment", env.name
            ]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "MWAA Tasks Running"
          period  = 300
          stat    = "Average"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 8
        height = 6

        properties = {
          metrics = [
            for env in var.mwaa_environments : [
              "AWS/MWAA", "QueuedTasks", "Environment", env.name
            ]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "MWAA Tasks Queued"
          period  = 300
          stat    = "Average"
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 6
        width  = 8
        height = 6

        properties = {
          metrics = [
            for env in var.mwaa_environments : [
              "AWS/MWAA", "ActiveConnectionCount", "Environment", env.name
            ]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "MWAA Active Connection Count"
          period  = 300
          stat    = "Average"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6

        properties = {
          metrics = [
            for env in var.mwaa_environments : [
              "AWS/MWAA", "CPUUtilization", "Cluster", "BaseWorker", "Environment", env.name
            ]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "MWAA Worker CPU Utilization"
          period  = 300
          stat    = "Average"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6

        properties = {
          metrics = [
            for env in var.mwaa_environments : [
              "AWS/MWAA", "MemoryUtilization", "Cluster", "BaseWorker", "Environment", env.name
            ]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "MWAA Worker Memory Utilization"
          period  = 300
          stat    = "Average"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 18
        width  = 8
        height = 6

        properties = {
          metrics = [
            for env in var.mwaa_environments : [
              "AmazonMWAA", "TotalParseTime", "Function", "DAG Processing", "Environment", env.name
            ]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "MWAA DAG Processing Parse Time"
          period  = 300
          stat    = "Average"
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 18
        width  = 8
        height = 6

        properties = {
          metrics = [
            for env in var.mwaa_environments : [
              "AmazonMWAA", "ImportErrors", "Function", "DAG Processing", "Environment", env.name
            ]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "MWAA DAG Import Errors"
          period  = 300
          stat    = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 18
        width  = 8
        height = 6

        properties = {
          metrics = [
            for env in var.mwaa_environments : [
              "AWS/MWAA", "CPUUtilization", "Cluster", "WebServer", "Environment", env.name
            ]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "MWAA Scheduler CPU Utilization"
          period  = 300
          stat    = "Average"
        }
      }
    ]
  })
}