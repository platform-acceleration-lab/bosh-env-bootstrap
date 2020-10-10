#!/usr/bin/env bash

if [ $# -ne 3 ]; then
    echo "Usage: ./provision-gcp-projects.sh <cohort prefix> <cohort id> <gcp parent folder id>"
    exit 1
fi

cohort_prefix=$1
cohort_id=$2
gcp_parent_folder_id=$3

projects=$(ls -d envs/${cohort_prefix}-*)

echo "The following projects will be provisioned:"

for project in ${projects[*]}; do
    echo "- ${project}"
done

read -p "Are you sure (y/n) ? " -r

if [[ ! $REPLY =~ ^[Yy]  ]]; then
  exit 2
fi

result=$(gcloud resource-manager folders list \
  --folder="${gcp_parent_folder_id}" \
  --filter="display_name=cohort-${cohort_id}" \
  --format=json)

size=$(echo $result | jq 'length')

if [[ $size -eq 0 ]]
then
  gcp_folder_id=$(gcloud resource-manager folders create \
    --folder="${gcp_parent_folder_id}" \
    --display-name="cohort-${cohort_id}" \
    --format json | jq -r .name |  cut -d / -f 2)
else
  gcp_folder_id=$(gcloud resource-manager folders list \
    --folder="${gcp_parent_folder_id}" \
    --filter="display_name=cohort-${cohort_id}" \
    --format json | jq -r '.[0].name' | cut -d / -f 2
  )
fi

tmux new-session -s "provision-${cohort_id}" -n first-window -d

for project in ${projects[*]}; do
  tmux new-window -t "provision-${cohort_id}" bash -lic "${project}/create-project.sh ${gcp_folder_id} 2>&1 | tee ${project}/provision-log.txt";
done

tmux kill-window -t first-window
