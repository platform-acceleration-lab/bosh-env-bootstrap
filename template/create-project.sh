#!/usr/bin/env bash

if [ $# -ne 1 ]; then
  echo "Usage: create-project.sh <gcp folder id>"
  exit 1
fi

ORGANIZATION_ID=265595624405
CLOUDHEALTH_SERVICE_ACCOUNT_NAME=cloudhealthpivotal
BILLING_ID=0076DC-766E1F-EBDCB8

pushd $( dirname "${BASH_SOURCE[0]}" )

export username=$(basename $(pwd))
export PROJECT_ID=${PROJECT_ID:-${username}}
export SERVICE_ACCOUNT=${username}@${PROJECT_ID}.iam.gserviceaccount.com
export SERVICE_ACCOUNT_KEY=${username}-service-account-key.json

gcp_folder_id=$1

gcloud projects describe ${PROJECT_ID}

if [ $? -ne 0 ]; then

  set -e
  gcloud projects create ${PROJECT_ID} --folder=${gcp_folder_id} \
    --labels="business_unit=mapbu,cost_center=us1983017,short_cost_center=83107"
  set +e

else
  echo "project ${PROJECT_ID} already exists, proceeding.."
fi

set -e
gcloud beta billing projects link ${PROJECT_ID} --billing-account=${BILLING_ID}
gcloud services enable \
  compute.googleapis.com \
  iam.googleapis.com \
  cloudresourcemanager.googleapis.com \
  cloudbilling.googleapis.com \
  storage-component.googleapis.com \
  container.googleapis.com \
  dns.googleapis.com \
  --project ${PROJECT_ID}
set +e

gcloud iam service-accounts describe ${SERVICE_ACCOUNT}

if [ $? -ne 0 ]; then

  gcloud iam service-accounts create ${username} \
    --display-name "${username} service account" \
    --project ${PROJECT_ID}

else
  echo "service account ${SERVICE_ACCOUNT} already exists, proceeding.."
fi

# -s means "file exists and size is > 0"
if [ -s "${SERVICE_ACCOUNT_KEY}" ]; then
  echo "service account key already exists, proceeding.."
else
  gcloud iam service-accounts keys create ${SERVICE_ACCOUNT_KEY} \
    --iam-account ${SERVICE_ACCOUNT} \
    --project ${PROJECT_ID}
fi

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member serviceAccount:${SERVICE_ACCOUNT} \
  --role "roles/owner" \
  --project ${PROJECT_ID} \
  --no-user-output-enabled

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member user:$(cat ./user.txt) \
  --role "roles/editor"

gcloud iam service-accounts describe ${CLOUDHEALTH_SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com

if [ $? -ne 0 ]; then

  gcloud iam service-accounts create ${CLOUDHEALTH_SERVICE_ACCOUNT_NAME} \
    --display-name=CloudHealthPivotal \
    --project ${PROJECT_ID}

else
  echo "service account ${CLOUDHEALTH_SERVICE_ACCOUNT_NAME} already exists, proceeding.."
fi

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member=serviceAccount:${CLOUDHEALTH_SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com \
  --role=organizations/${ORGANIZATION_ID}/roles/cloudhealthrole \
  --project ${PROJECT_ID} \
  --no-user-output-enabled

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member=serviceAccount:${CLOUDHEALTH_SERVICE_ACCOUNT_NAME}@cma-test.iam.gserviceaccount.com \
  --role=roles/viewer \
  --project ${PROJECT_ID} \
  --no-user-output-enabled

echo "project created."
