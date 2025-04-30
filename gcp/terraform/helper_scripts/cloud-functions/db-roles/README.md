# Install dependecnies
pip install -r requirements.txt
# Run debugger (launch.json is included)
# Sample payload
curl -k -X POST http://localhost:7788/execute_role_management \
    -H "Content-Type: application/json" \
    -d '{"instance_name":"a083gt-dev:northamerica-northeast1:businesses-db-dev","gcs_uri":"gs://common-tools-sql/readonly.sql","database":"legal-entities","owner":"business-api","agent":"business-api"}'
