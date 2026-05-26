import os
import re
import csv
from datetime import datetime

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
GCP_DIR = os.path.dirname(SCRIPT_DIR)
OUTPUT_DIR = os.path.join(SCRIPT_DIR, "output")
os.makedirs(OUTPUT_DIR, exist_ok=True)
TF_DIR = os.path.join(GCP_DIR, "terraform")
TODAY = datetime.now().strftime("%Y-%m-%d")

# Mapping of IAM roles to GCP Products
ROLE_TO_PRODUCT = {
    "cloudsql": "Cloud SQL",
    "run": "Cloud Run",
    "pubsub": "Pub/Sub",
    "storage": "Cloud Storage",
    "apigee": "Apigee",
    "cloudtasks": "Cloud Tasks",
    "firebase": "Firebase",
    "secretmanager": "Secret Manager",
    "artifactregistry": "Artifact Registry",
    "redis": "MemoryStore (Redis)",
    "serverless": "Serverless VPC Access",
    "compute": "Compute Engine",
    "logging": "Cloud Logging",
    "cloudbuild": "Cloud Build",
    "firebaseauth": "Firebase Auth"
}

def extract_gcp_products(block_text):
    products = set()
    # Find all references to "roles/... "
    matches = re.findall(r'roles/([a-zA-Z0-9_-]+)\.', block_text)
    for service_prefix in matches:
        if service_prefix in ROLE_TO_PRODUCT:
            products.add(ROLE_TO_PRODUCT[service_prefix])
            
    # Also check for explicit instance definition implies Cloud SQL
    if "instances =" in block_text or "instances=" in block_text or "instances  =" in block_text:
        products.add("Cloud SQL")
        
    return sorted(list(products))

def main():
    projects = []
    
    if not os.path.isdir(TF_DIR):
        print(f"Terraform directory not found at {TF_DIR}")
        return
        
    processed_configs = 0
    for filename in os.listdir(TF_DIR):
        if not filename.endswith(".auto.tfvars") or not filename.startswith("_config_project_"):
            continue
            
        processed_configs += 1
        filepath = os.path.join(TF_DIR, filename)
        with open(filepath, "r") as f:
            content = f.read()

        # Split content by the pattern that starts a new project config block
        blocks = re.split(r'\n\s*"([a-zA-Z0-9_-]+)"\s*=\s*\{', "\n" + content)
        
        for i in range(1, len(blocks)-1, 2):
            alias = blocks[i]
            block_content = blocks[i+1]
            
            # Find project_id
            m_id = re.search(r'project_id\s*=\s*"([^"]+)"', block_content)
            if not m_id:
                continue
            project_id = m_id.group(1)
            
            # Find env
            m_env = re.search(r'env\s*=\s*"([^"]+)"', block_content)
            env = m_env.group(1) if m_env else "unknown"
            
            # Assume product is the alias without the -env suffix
            internal_product = alias
            if internal_product.endswith(f"-{env}"):
                internal_product = internal_product[:-(len(env)+1)]
                
            # Internal product cleanup
            internal_product = internal_product.replace('-', ' ').title()
            
            gcp_products = extract_gcp_products(block_content)
            
            projects.append({
                "project_id": project_id,
                "alias": alias,
                "internal_product": internal_product,
                "env": env.upper(),
                "gcp_products": ", ".join(gcp_products),
                "link": f"https://console.cloud.google.com/home/dashboard?project={project_id}"
            })
            
    # Generate Output
    md_file = os.path.join(OUTPUT_DIR, f"gcp_projects_{TODAY}.md")
    csv_file = os.path.join(OUTPUT_DIR, f"gcp_projects_{TODAY}.csv")
    
    # Sort by product then environment
    projects.sort(key=lambda x: (x['internal_product'], x['env']))
    
    with open(md_file, "w") as f:
        f.write("# GCP Project Inventory\n\n")
        f.write(f"**Generated:** {TODAY}\n\n")
        f.write("| Internal Product | Project Name | Environment | GCP Products & APIs Enabled |\n")
        f.write("|------------------|--------------|-------------|-----------------------------|\n")
        for p in projects:
            f.write(f"| {p['internal_product']} | [{p['project_id']}]({p['link']}) | {p['env']} | {p['gcp_products']} |\n")

    with open(csv_file, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=projects[0].keys())
        writer.writeheader()
        writer.writerows(projects)
        
    print(f"Scanned {processed_configs} config files. Extracted {len(projects)} projects.")
    print(f"Generated {md_file} and {csv_file}")

if __name__ == "__main__":
    main()
