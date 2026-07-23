import json
import os
import time
import urllib.request
import urllib.error

import boto3
import psycopg2


def handler(event, context):
    project_name = os.environ["PROJECT_NAME"]
    alb_dns = os.environ["ALB_DNS_NAME"]
    db_secret_arn = os.environ["DB_SECRET_ARN"]
    sns_topic_arn = os.environ.get("SNS_TOPIC_ARN", "")
    ecs_cluster = os.environ.get("ECS_CLUSTER_NAME", "")
    ecs_service = os.environ.get("ECS_SERVICE_NAME", "")
    db_allocated_storage_gb = int(os.environ.get("DB_ALLOCATED_STORAGE_GB", "20"))

    cloudwatch = boto3.client("cloudwatch")
    metrics = []
    alerts = []

    alb_healthy = 0
    alb_response_ms = 0
    try:
        start = time.time()
        req = urllib.request.Request(f"http://{alb_dns}/", method="GET")
        req.add_header("User-Agent", "HealthMonitor/1.0")
        response = urllib.request.urlopen(req, timeout=10)
        alb_response_ms = (time.time() - start) * 1000
        alb_healthy = 1 if response.getcode() == 200 else 0
    except Exception as e:
        print(f"ALB health check failed: {e}")
        alerts.append(f"ALB health check failed: {e}")

    metrics.extend(
        [
            {
                "MetricName": "ALBHealthy",
                "Value": alb_healthy,
                "Unit": "Count",
                "Dimensions": [{"Name": "Project", "Value": project_name}],
            },
            {
                "MetricName": "ALBResponseTime",
                "Value": alb_response_ms,
                "Unit": "Milliseconds",
                "Dimensions": [{"Name": "Project", "Value": project_name}],
            },
        ]
    )

    db_healthy = 0
    active_connections = 0
    db_size_percent = 0.0
    try:
        sm = boto3.client("secretsmanager")
        secret = json.loads(
            sm.get_secret_value(SecretId=db_secret_arn)["SecretString"]
        )

        conn = psycopg2.connect(
            host=secret["host"],
            port=int(secret["port"]),
            dbname=secret["dbname"],
            user=secret["username"],
            password=secret["password"],
            connect_timeout=10,
        )
        cur = conn.cursor()

        cur.execute(
            "SELECT numbackends FROM pg_stat_database WHERE datname = %s",
            (secret["dbname"],),
        )
        row = cur.fetchone()
        active_connections = row[0] if row else 0

        cur.execute("SELECT pg_database_size(%s)", (secret["dbname"],))
        row = cur.fetchone()
        db_size_bytes = row[0] if row else 0
        db_allocated_bytes = db_allocated_storage_gb * 1024 * 1024 * 1024
        db_size_percent = (db_size_bytes / db_allocated_bytes) * 100 if db_allocated_bytes > 0 else 0

        cur.close()
        conn.close()
        db_healthy = 1
    except Exception as e:
        print(f"RDS health check failed: {e}")
        alerts.append(f"RDS health check failed: {e}")

    metrics.extend(
        [
            {
                "MetricName": "RDSHealthy",
                "Value": db_healthy,
                "Unit": "Count",
                "Dimensions": [{"Name": "Project", "Value": project_name}],
            },
            {
                "MetricName": "ActiveDBConnections",
                "Value": active_connections,
                "Unit": "Count",
                "Dimensions": [{"Name": "Project", "Value": project_name}],
            },
            {
                "MetricName": "DatabaseSizePercent",
                "Value": round(db_size_percent, 2),
                "Unit": "Percent",
                "Dimensions": [{"Name": "Project", "Value": project_name}],
            },
        ]
    )

    # ECS container health checks
    containers_healthy = 0
    containers_total = 0
    if ecs_cluster and ecs_service:
        try:
            ecs = boto3.client("ecs")
            tasks_resp = ecs.list_tasks(
                cluster=ecs_cluster, serviceName=ecs_service, desiredStatus="RUNNING"
            )
            task_arns = tasks_resp.get("taskArns", [])
            containers_total = len(task_arns)

            if task_arns:
                details = ecs.describe_tasks(cluster=ecs_cluster, tasks=task_arns)
                for task in details.get("tasks", []):
                    all_healthy = all(
                        c.get("healthStatus") == "HEALTHY"
                        for c in task.get("containers", [])
                        if c.get("healthStatus") != "UNKNOWN"
                    )
                    if all_healthy and task.get("lastStatus") == "RUNNING":
                        containers_healthy += 1

            if containers_total > 0 and containers_healthy < containers_total:
                alerts.append(
                    f"ECS: {containers_healthy}/{containers_total} tasks healthy"
                )
        except Exception as e:
            print(f"ECS health check failed: {e}")
            alerts.append(f"ECS health check failed: {e}")

    metrics.extend(
        [
            {
                "MetricName": "ECSHealthyTasks",
                "Value": containers_healthy,
                "Unit": "Count",
                "Dimensions": [{"Name": "Project", "Value": project_name}],
            },
            {
                "MetricName": "ECSTotalTasks",
                "Value": containers_total,
                "Unit": "Count",
                "Dimensions": [{"Name": "Project", "Value": project_name}],
            },
        ]
    )

    cloudwatch.put_metric_data(Namespace="Custom/HealthMonitor", MetricData=metrics)

    # Send SNS alert if any checks failed
    if alerts and sns_topic_arn:
        try:
            sns = boto3.client("sns")
            message = f"Health Monitor Alert - {project_name}\n\n"
            message += "\n".join(f"- {a}" for a in alerts)
            message += f"\n\nTimestamp: {time.strftime('%Y-%m-%d %H:%M:%S UTC', time.gmtime())}"
            sns.publish(
                TopicArn=sns_topic_arn,
                Subject=f"[{project_name}] Health Check Failed",
                Message=message,
            )
            print(f"Alert sent to SNS: {len(alerts)} issue(s)")
        except Exception as e:
            print(f"Failed to send SNS alert: {e}")

    result = {
        "alb_healthy": bool(alb_healthy),
        "alb_response_ms": alb_response_ms,
        "db_healthy": bool(db_healthy),
        "active_connections": active_connections,
        "db_size_percent": round(db_size_percent, 2),
        "containers_healthy": containers_healthy,
        "containers_total": containers_total,
        "alerts_sent": len(alerts) if alerts else 0,
    }

    print(json.dumps(result))
    return {"statusCode": 200, "body": json.dumps(result)}
