#!/usr/bin/env -S uv run
# Copyright 2026

# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "google-cloud-monitoring",
#     "google-cloud-logging",
#     "google-auth",
#     "python-dateutil",
#     "numpy",
#     "jinja2"
# ]
# ///

import argparse
import sys
import os
import json
import calendar
import numpy as np
import jinja2
from datetime import datetime
from dateutil import parser
import google.auth
from google.cloud import monitoring_v3
from google.cloud import logging_v2

def sparkline(values):
    """Generate a sparkline string for a list of values."""
    if not values:
         return ""
    bars = u'  ▂▃▄▅▆▇█'
    mx, mn = max(values), min(values)
    if mx == mn:
        return bars[-1] * len(values)
    return "".join([bars[min(len(bars)-1, int((v - mn) / (mx - mn) * len(bars)))] for v in values])

def get_service_id(monitoring_client, project_id, service_name):
    """Finds the Monitoring Service ID matching the given display name."""
    parent = f"projects/{project_id}"
    for service in monitoring_client.list_services(parent=parent):
        if service.display_name == service_name:
            return service.name.split("/")[-1]
        # Cloud Run services often use the same string for ID and name
        if service.name.split("/")[-1] == service_name:
             return service_name
    return None

def fetch_slos_and_compliance(monitoring_client, project_id, service_id, start_time, end_time):
    """Fetches SLO targets and evaluates their actual SLI compliance ratio."""
    parent = f"projects/{project_id}/services/{service_id}"
    slos = []
    for slo in monitoring_client.list_service_level_objectives(parent=parent):
        goal = slo.goal
        display_name = slo.display_name
        slo_id = slo.name.split("/")[-1]
        
        # Calculate real compliance
        compliance_filter = f'select_slo_compliance("projects/{project_id}/services/{service_id}/serviceLevelObjectives/{slo_id}")'
        # Ensure interval is just a short 5-minute window preceding end_time
        # for select_slo_compliance without aggregation
        eval_start = end_time.timestamp() - 300
        interval = monitoring_v3.TimeInterval({
            "end_time": {"seconds": int(end_time.timestamp())},
            "start_time": {"seconds": int(eval_start)}
        })
        
        # We just query without aggregation to get the point value that `select_slo_compliance` emits
        request = monitoring_v3.ListTimeSeriesRequest(
            name=f"projects/{project_id}",
            filter=compliance_filter,
            interval=interval,
            view=monitoring_v3.ListTimeSeriesRequest.TimeSeriesView.FULL
        )
        points = []
        try:
            results = monitoring_client.list_time_series(request=request)
            for ts in results:
                points.extend(ts.points)
        except Exception as e:
            compliance = "N/A"
            
        compliance = "N/A"
        compliance_val = None
        if points:
             # Sort points by time and get the latest
             points.sort(key=lambda p: p.interval.end_time.timestamp(), reverse=True)
             compliance_val = points[0].value.double_value
             compliance = f"{compliance_val * 100:.3f}%"
             
        status = "🔴"
        if compliance_val is not None:
             if compliance_val >= goal:
                  status = "🟢"
        
        slos.append({
            "display_name": display_name,
            "goal": f"{goal * 100:.2f}%",
            "compliance": compliance,
            "status": status
        })
    return slos

def fetch_metric_stats(monitoring_client, project_id, service_name, start_time, end_time, metric_type):
    """Fetches timeseries points, reduces them into buckets for sparkline, and gets count/sum/max/avg."""
    interval = monitoring_v3.TimeInterval({
        "end_time": {"seconds": int(end_time.timestamp())},
        "start_time": {"seconds": int(start_time.timestamp())}
    })
    filter_expr = f'metric.type="{metric_type}" AND resource.labels.service_name="{service_name}"'
    
    request = monitoring_v3.ListTimeSeriesRequest(
        name=f"projects/{project_id}",
        filter=filter_expr,
        interval=interval,
        view=monitoring_v3.ListTimeSeriesRequest.TimeSeriesView.FULL
    )
    
    all_points = []
    try:
         for ts in monitoring_client.list_time_series(request=request):
             for point in ts.points:
                 if point.value.double_value > 0:
                      all_points.append(point.value.double_value)
                 elif point.value.int64_value > 0:
                      all_points.append(point.value.int64_value)
                 elif point.value.distribution_value.mean > 0:
                      all_points.append(point.value.distribution_value.mean)
    except Exception as e:
         pass
         
    if not all_points:
         return {"shape": "______", "sum": 0, "avg": 0, "max": 0}
         
    # Binning to 16 points for sparkline
    binned = []
    num_bins = 16
    chunk_size = max(1, len(all_points) // num_bins)
    for i in range(0, len(all_points), chunk_size):
         binned.append(np.mean(all_points[i:i+chunk_size]))
         
    return {
        "shape": sparkline(binned),
        "sum": np.sum(all_points),
        "avg": np.mean(all_points),
        "max": np.max(all_points)
    }

def fetch_top_errors(logging_client, project_id, service_name, start_time, end_time):
    """Fetches the latest ERROR logs and deduplicates basic payloads."""
    # Convert dates to RFC 3339 without timezone offset formatting issues for gcloud logging
    start_str = start_time.strftime("%Y-%m-%dT%H:%M:%SZ")
    end_str = end_time.strftime("%Y-%m-%dT%H:%M:%SZ")
    
    query = f"""
    resource.type="cloud_run_revision" 
    AND resource.labels.service_name="{service_name}" 
    AND severity>=ERROR 
    AND timestamp>="{start_str}" 
    AND timestamp<="{end_str}"
    """
    
    errors = []
    try:
        # Fetch up to 50 logs
        iterator = logging_client.list_entries(filter_=query, max_results=50, order_by=logging_v2.DESCENDING)
        for entry in iterator:
             # StructEntry stores json in `payload`, TextEntry uses `payload` (as str)
             content = ""
             if isinstance(entry.payload, dict):
                 content = entry.payload.get("message", json.dumps(entry.payload))
             elif isinstance(entry.payload, str):
                 content = entry.payload
                 
             if content:
                 errors.append(content)
    except Exception:
        pass
        
    unique_errors = []
    seen = set()
    for e in errors:
         first_line = e.split('\\n')[0][:100]
         if first_line not in seen:
              seen.add(first_line)
              unique_errors.append(e)
              if len(unique_errors) >= 3:
                  break
    
    return unique_errors

def generate_report(project_id, service_name, start_date, end_date, template_path):
    start_time = parser.parse(start_date)
    end_time = parser.parse(end_date)
    
    credentials, _ = google.auth.default()
    monitoring_client = monitoring_v3.MetricServiceClient(credentials=credentials)
    service_monitor_client = monitoring_v3.ServiceMonitoringServiceClient(credentials=credentials)
    logging_client = logging_v2.Client(credentials=credentials, project=project_id)
    
    service_id = get_service_id(service_monitor_client, project_id, service_name)
    
    slos = []
    if service_id:
        slos = fetch_slos_and_compliance(monitoring_client, project_id, service_id, start_time, end_time)
        
    req_stats = fetch_metric_stats(monitoring_client, project_id, service_name, start_time, end_time, "run.googleapis.com/request_count")
    lat_stats = fetch_metric_stats(monitoring_client, project_id, service_name, start_time, end_time, "run.googleapis.com/request_latencies")
    
    errors = fetch_top_errors(logging_client, project_id, service_name, start_time, end_time)
    
    # Load default template if none explicitly provided by looking adjacent to this script
    if not template_path:
        template_path = os.path.join(os.path.dirname(__file__), "sre_report_template.md.j2")
        
    with open(template_path, 'r') as f:
        template_str = f.read()
        
    template = jinja2.Template(template_str)
    md = template.render(
        project_id=project_id,
        service_name=service_name,
        start_time=start_time.isoformat(),
        end_time=end_time.isoformat(),
        slos=slos,
        req_stats=req_stats,
        lat_stats=lat_stats,
        errors=errors
    )
    return md

if __name__ == "__main__":
    parser_args = argparse.ArgumentParser(description="Generate SRE Report for a Service")
    parser_args.add_argument("--project", required=True, help="GCP Project ID")
    parser_args.add_argument("--service-name", required=True, help="Cloud Run Service Name")
    parser_args.add_argument("--month", help="Reporting month (YYYYMM). Defaults to last full calendar month.")
    parser_args.add_argument("--template", help="Optional path to a Jinja2 template file. Uses default if not provided.")
    parser_args.add_argument("--output", help="Output MD file name")
    
    args = parser_args.parse_args()
    
    if args.month:
        try:
             year = int(args.month[:4])
             month = int(args.month[4:])
        except ValueError:
             print("Error: --month must be in YYYYMM format.")
             sys.exit(1)
    else:
        now = datetime.utcnow()
        if now.month == 1:
             year = now.year - 1
             month = 12
        else:
             year = now.year
             month = now.month - 1
             
    start_date = f"{year}-{month:02d}-01T00:00:00Z"
    last_day = calendar.monthrange(year, month)[1]
    end_date = f"{year}-{month:02d}-{last_day:02d}T23:59:59Z"
    
    print(f"Generating SRE report for {year}-{month:02d}...")
    report_md = generate_report(args.project, args.service_name, start_date, end_date, getattr(args, 'template', None))
    
    if not args.output:
        month_name = calendar.month_name[month].lower()
        output_dir = os.path.join(os.path.dirname(__file__), "output")
        os.makedirs(output_dir, exist_ok=True)
        args.output = os.path.join(output_dir, f"{args.service_name}-{month_name}-{year}_sre_report.md")
        
    with open(args.output, 'w') as f:
        f.write(report_md)
    print(f"Report successfully saved to {args.output}")
