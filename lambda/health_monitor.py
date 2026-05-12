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

    cloudwatch = boto3.client("cloudwatch")
    metrics = []

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
    db_size_bytes = 0
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

        cur.close()
        conn.close()
        db_healthy = 1
    except Exception as e:
        print(f"RDS health check failed: {e}")

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
                "MetricName": "DatabaseSizeBytes",
                "Value": db_size_bytes,
                "Unit": "Bytes",
                "Dimensions": [{"Name": "Project", "Value": project_name}],
            },
        ]
    )

    cloudwatch.put_metric_data(Namespace="Custom/HealthMonitor", MetricData=metrics)

    result = {
        "alb_healthy": bool(alb_healthy),
        "alb_response_ms": alb_response_ms,
        "db_healthy": bool(db_healthy),
        "active_connections": active_connections,
        "db_size_bytes": db_size_bytes,
    }

    print(json.dumps(result))
    return {"statusCode": 200, "body": json.dumps(result)}
