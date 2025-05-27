#!/bin/bash
# This script is used to send a callback to Ansible Automation Platform (AAP) after provisioning a resource.
curl -k -s -i -X POST -H 'Content-Type:application/json' --data '{"host_config_key": "sample_key"}' https://<aap_host>/api/controller/v2/job_templates/<template_id>/callback/ 2>&1



