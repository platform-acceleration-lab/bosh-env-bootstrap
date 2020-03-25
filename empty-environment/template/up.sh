#!/bin/bash

export ORGANIZATION_ID=265595624405
export CLOUDHEALTH_SERVICE_ACCOUNT_NAME=cloudhealthpivotal
export BILLING_ID=0076DC-766E1F-EBDCB8

pushd $( dirname "${BASH_SOURCE[0]}" )

export PROJECT_ID=$(basename $(pwd))

if gcloud projects create ${PROJECT_ID} --folder=${FOLDER_ID}; then

  gcloud beta billing projects link ${PROJECT_ID} --billing-account=${BILLING_ID}

  gcloud services enable \
      iam.googleapis.com \
      cloudresourcemanager.googleapis.com \
      dns.googleapis.com \
      sqladmin.googleapis.com \
      compute.googleapis.com \
      cloudbilling.googleapis.com \
      storage-component.googleapis.com \
      --project ${PROJECT_ID}

else
  echo "${PROJECT_ID} could not be created. Aborting environment creation."
  exit 1
fi

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member user:$(cat ./user.txt) \
  --role "roles/editor"

gcloud iam service-accounts create ${CLOUDHEALTH_SERVICE_ACCOUNT_NAME} \
  --display-name=CloudHealthPivotal \
  --project ${PROJECT_ID}

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

echo "${PROJECT_ID} successfully provisioned."
