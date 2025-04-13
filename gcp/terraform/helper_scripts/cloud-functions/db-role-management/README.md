# Install dependecnies
python3.12 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
# Run debugger (launch.json is included)
# Sample payload
curl -k -X POST http://localhost:7799/grant_db_role \
    -H "Content-Type: application/json" \
    -d '{"instance_name":"a083gt-dev:northamerica-northeast1:businesses-db-dev","role":"readonly","database":"legal-entities","user":"andriy.bolyachevets@gov.bc.ca"}'