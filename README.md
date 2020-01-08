# Purpose

These are the environment bootstrap scripts for spinning up GCP projects
with a jumpbox and BOSH director installed.

## Usage

Clone this repo onto a Linux system.
[GCP Cloud Shell](https://cloud.google.com/shell/docs/quickstart) is a
simple option but hosting a small dedicated Ubuntu VM on an existing GCP
project with the [GCloud SDK](https://cloud.google.com/sdk/install)
installed and authenticated (as project owner) would represent a more robust
configuration.

There are two options available.

-   Create _each_ director in a dedicated GCP project.
-   Create _all_ directors in one GCP project.

The primary script to use is `init.sh`.

Before using `init.sh` you _must_ ensure that each of the student emails
map directly to a genuine GCP account.
Failure to do this will cause the scripts to fail.

## The `init.sh` script

The `init.sh` is used to generate directories that contain templates and
up/down scripts which know how to provision and reclaim BOSH director
VMs.

Inputs:

Command line:
- A `GROUP_ID` variable (optional, randomized when omitted) 
  This is an identifier for the set of GCP projects being created.
- A list of emails which correspond to genuine GCP accounts

Usage:

```bash
export GROUP_ID=123456789
./init.sh fbloggs@abc.com gbloggs@xyz.com
```

Inputs via file:
* `admins.txt` More or less static list of CloudOps admin accounts.
   To be edited as team members roll on and off.
   List of accounts to be given owner permissions on generated GCP project
* `instructors.txt` Instructors for the cohort being provisioned.
   To be edited for each cohort.
   List of accounts to be given owner permissions on generated GCP project

Output:

-   A directory called `envs` that contains the directories for the
    environments requested.
    In this case `bosh-123456789-fbloggs` and `bosh-123456789-gbloggs`.

## Create a folder for the class

In the GCP resource manager, within the `pivotal.io` organization,
within the `CSO-Education` folder, find the folder for the course you
are creating environments for.
Within this folder, make a new folder for the class using the cohort id
as the name.
Take note of the folder id that is associated with this newly created
folder, as it will be needed in the following step.

## The generated `up.sh` script

It is used to deploy a jumpbox and a director.

Inputs:

- folder id variable

Usage:

From the top-level directory, to create a director in its own dedicated
project, run the following.

```bash
FOLDER_ID=123456789 ./envs/[env-to-spin-up]/up.sh
```

After the `up.sh` script finishes, check the output for any uncaught errors.

The following manual steps must be taken to complete the provisioning:
Log into the GCP Console, locate the provisioned account, go to the `IAM and admin` page
(navigate using the upper-left hamburger),
and change the role of all the admins, instructors, and the student to `Owner`.

Output:

-   A _*-env_ file.
    This file contains all variables needed to connect to the BOSH
    director that was spun up.

Source an env file to interact with the respective director using the
BOSH CLI.

## Testing a deployed director

To test an environment we need to do the following

- [Install](https://bosh.io/docs/cli-v2-install/) the BOSH cli.
- Source the environment variables of the target environment.
- Invoke a BOSH cli method which depends upon the BOSH director.

For example, the following will produce a meaningful response from the
director.

```bash
source ./envs/[env-to-spin-up]/[env-to-spin-up]-env
bosh env
```

## The generated `down.sh` script

This will remove the director and jumpbox, clean up the VMs, disks and
networks and remove all users the up script had created.

Usage:

From the `envs` directory run the following.

```bash
./[env-to-take-down]/down.sh
```

Output:

- A clean GCP project with all traces of the director removed.

## Multiple environments

Use [tmux](https://en.wikipedia.org/wiki/Tmux) to bring up multiple
environments at once.
It is also helpful to persist logs using the tee command.
in the process so that you can troubleshoot later on if things go wrong.

To force multiple environments to appear inside a single project, you
must first `export` the `PROJECT_ID` variable.
It is a similar story for the `BILLING_ID` if new projects are to be
created.

Then you can use the following.

```bash
for project in $(ls -d ./envs/${GROUP_ID}*); do
  tmux new-window bash -lic "${project}/up.sh 2>&1 | tee ${project}/up-log.txt";
done
```

To take the environments _down_.

```bash
for project in $(ls -d ./envs/${GROUP_ID}*); do
  tmux new-window bash -lic "${project}/down.sh 2>&1 | tee ${project}/down-log.txt";
done
```

## Email Michael Nemish with environment info

After the projects have been provisioned, send an email to
mnemish@pivotal.io with a list of GCP project that have been created.

After spinning down the projects, also be sure to send him an email to
let him know.
