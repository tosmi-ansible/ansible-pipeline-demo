# Ansible Pipeline Demo

This repository contains a simple pipeline that demonstrate how to

- Onboard new teams to Ansible Controller (WIP)
- Validate Ansible code in an automated fashion
- Merging changes automatically to different repository branches after
  validation
- Triggering Ansible Controller jobs after merging to rollout changes

The demo is running in OpenShift, for reasons why see [here](#why-openshift).

## Table of contents

* [Motivation](#motivation)
* [Tools](#tools)
* [Pipeline overview](#pipeline-overview)
* [Onboarding new teams](#onboarding-new-teams)
* [Proposed developer workflow](#proposed-developer-workflow)
* [Why OpenShift?](#why-openshift?)
* [Prerequisites](#prerequisites)
* [Infrastructure setup](#infrastructure-setup)
* [Preparing required content](#preparing-required-content)
* [Running the demo](#running-the-demo)
* [Possible improvements to the pipeline](#possible-improvements-to-the-pipeline)
* [Tips and Tricks](#tips-and-tricks)

## Motivation

Using Ansible for automation is only the starting point to a longer
journey. For most larger automation setups the following questions
arise after automating the first tasks:

- How should we onboard new teams to Automation Platform?
- How can we test our Ansible code base before applying it to
  production systems?
- Which tools are available for testing Ansible code?
- Is it possible to fully automate the whole workflow of testing
  Ansible code and bringing it to production?

Answering the questions above, when starting with a blank page is
hard. There are multiple solutions and even more tools to achieve the
desired result.

This Demo setup tries to answer some of these questions. We only
scratch the surface of what's actually possible. It's not the
definitive answer but should help getting started without staring at
that annoying blank page.

## Tools

We use the following tools to implement our pipeline

- [Gitea](https://gitea.io/en-us/):
  - Storing our Ansible code base and
  - our Ansible Controller configuration
- [Tekton](https://tekton.dev/) for implementing our pipeline
- [Ansible Controller](https://www.ansible.com/products/controller)
  for executing Ansible code

## Onboarding new Teams

The goal is to onboard new teams to Automation Platform in an
automated way. New teams should automatically get:

- A tower organization with one admin user for that organization
  - The admin user can onboard other users in his team
- A GIT repository for storing Ansible Controller configuration
  - Everything the team configures should be done via this repository
  - Onboarding creates a Job template to apply the configuration
- An opinionated pipeline that validates automation code before rollout
- A GIT repository containing a sample Ansible collection that is
  validated by the pipeline described below

Everything should be stored in GIT repositories:

- The automation code use configure systems, network devices and so on
- The configuration of Ansible Controller itself

Teams on-boarded to Ansible Controller are responsible for those two
repositories.

## Pipeline overview

The graphic depicts our proposed setup:

![Overview](images/overview.drawio.png)

We are going to deploy required tools in 3 separate OpenShift namespace:

- Gitea: for installation of Gitea
- ansible-pipeline: for storing required Tekton pipeline objects like
  - Tasks
  - Pipelines
  - EventTriggers
- ansible-automation-platform: for our installation of a minimal
  Automation Controller instance

Don't worry about setting up all those tools, we got you covered
here. See section [Setup](#Setup).

You might ask yourself why the heck is this running in OpenShift?
Please see [here](#why-openshift) for an explanation.

## Proposed developer workflow

The basic idea is to implement the following developer workflow

1. Developer checks out GIT repository with automation code
1. Developer creates feature branch in automation code repository
1. Developer pushes feature branch to central repository
1. Push trigger creates a separate feature environment in Automation
   Controller for testing the feature branch
1. Developer modifies / extends automation code
1. Developer commits automation code changes and pushes feature branch
   to remote GIT repo
1. Code can also be tested by triggering the feature branch
   environment in Automation Controller
1. If manual test are successful developer opens merge request to the *main* branch
1. If merge request is accepted merge triggers a pipeline run
1. Pipeline tests code with ansible-lint
1. If ansible-lint returned no errors code is merged into development
   branch by the pipeline
1. Pipeline triggers a Job Template that configures all development hosts
1. If Job template executes successful a pull request is opened to
   production
1. The pipeline stops at this point
1. Merge request can be accepted and code is merge to production
   branch

This is just a very simple implementation of a possible pipeline but
we think it demonstrates the basic building blocks required.

What is a feature branch environment in Automation Controller?

This basically means that we create a separate Project in Automation
Controller that points to the git repository with the feature
branch. Furthermore we also create a new Job Template that executes code
in the feature branch on a number of selected hosts.

Purpose of this feature environment is to enable code testing on
dedicated development hosts. For example there is one dev host for
every flavor of operating system we use (e.g. RHEL8 and RHEL9).

### Creating a new feature

![Feature branch](images/feature_branch.drawio.png)

### Releasing a new feature

![Release feature](images/dev_prod.drawio.png)

## Why OpenShift?

Simple because we can and OpenShift provides an easy way of setting up
our infrastructure via tools like [Helm](https://helm.io) or
[Operators](https://operatorhub.io/).

OpenShift is not a strong requirement for this demo, any Kubernetes
distribution or even upstream Kubernetes could also be leveraged (but
is untested and might eat your beloved cat).

> :warning: **Persistent storage is required**: For Gitea and the
> Automation Controller you are going to need persistent storage in
> OpenShift or Kubernetes.

Deploying our pipeline would also be possible without OpenShift. The
only thing that needs to be replaced is Tekton. There are plenty
of options available:

- [Jenkins](https://www.jenkins.io) for the classic CI/CD tooling
- [Gitlab pipelines](https://docs.gitlab.com/ee/ci/pipelines/)

or various pipelines as a service implementations like

- [Circle CI](https://circleci.com/)
- [Travis](https://www.travis-ci.com/)

## Prerequisites

Running the pipeline was tested on an OpenShift 4.11 cluster with
[rook-ceph](https://rook.io/) for persistent storage.

Tekton and Ansible Controller are installed via
[OLM](https://olm.operatorframework.io/) so to use the setup procedure
described in [Setup](#setup) you also need an installation of OLM.

You also need the following tools installed, either via a container or
locally:

- Python 3
- Ansible

The `setup` Makefile tasks tries to install required Python 3
dependencies via [](collections/requirements.txt) and required Ansible
collections via [](collections/requirements.yml).

## Infrastructure setup

The root directory of this repository contains a [Makefile](Makefile)
to set everything up. Just run

```
make help
```
to get a list of available targets:

```
Usage: make <OPTIONS> ... <TARGETS>

Available targets are:


Usage:
  make <target>
  help             Show this help screen
  pythonlibs       Install required python libraries
  collections      Install required collections
  setup            Run setup playbook
  toc              Generate a simple markdown toc, does not support levels!
```

So

```
make setup
```

should

- Install Tekton pipelines via OLM
- Install Gitea in the `gitea` namespace
- Push a template collection to the
  `developer/ansible-example-collection` repository
- Install Ansible Automation Controller in the
  `ansible-automation-platform` namespace again via OLM

After running `make setup` you will receive a message with

- The URL for your Gitea instance
- Username and password for Gitea
- The URL for the Automation Controller
- Username and password for the Automation Controller

For example:

```
TASK [Print Ansible Controller route] ********************************************************************************************************************************************************ok: [localhost] => {
    "msg": [
        "Ansible Controller user    : admin",
        "Ansible Controller password: jwQPEvXwmSVT57edYzmPF9yDEOXnzwQ3",
        "Ansible Controller URL     : https://ctrl.apps.ocp.lan.stderr.at",
        "",
        "Go to https://ctrl.apps.ocp.lan.stderr.at and add a subscription!",
        "After adding the subscription execute 'make controller-content"
    ]
}
```

## Preparing required content

For getting the Automation Controller ready you need to provide a
valid subscription upon first login.

After adding a subscription run `make setup` again

```
make setup
```

to prepare Ansible Controller for this demo. This will

- Create a development and production project
- Create one job template to configure development hosts
- Create one job template to configure production hosts

## Running the Demo

This section contains instruction on how to run this demo.

### Creating a new feature

We would like to develop a new feature and push it to
production. Perform the steps listed below.

#### Step 1: Cloning the example collection from Gitea

Because we are using self signed certificates, we need to disable SSL
verification. We will also cache the password for a faster workflow.

NOTE: This is NOT recommended for production environments!

```
export GITEA_PASSWORD=$(oc extract secret/gitea-developer-password -n gitea --to=-)
export GITEA_HOST=$(oc get route gitea-https  -n gitea -o jsonpath='{.spec.host}')
git -c http.sslVerify=false clone https://developer:"$GITEA_PASSWORD"@"$GITEA_HOST"/developer/ansible-example-collection.git
cd ansible-example-collection
git config http.sslVerify false
```

#### Step 2: Create a new feature branch and push the branch

```
git checkout -b feature/fancy
git push -u origin feature/fancy
```

The push event is going to create

- A project in Ansible Controller with the name _Pipeline - SOE - Feature branch feature/fancy_
- A job template that uses the branch _feature/fancy_ in the GIT repository _ansible-example-collection_

#### Step 3: Develop and test code

Make use develop in the new feature branch _feature/fancy_:

```
git checkout feature/fancy
```

Change the message in _linux-soe.yml_, commit and push the change

```
git add linux-soe.yml
git commit -m 'implemented new fancy feature'
git push
```

#### Step 4: Test you code via Ansible controller

You can now trigger the job template _Pipeline - SOE - Feature branch
feature/fancy_ and check if everything is all right.

#### Step 5: Merge to code into the _main_ branch

When you are happy with your new feature merge the branch _feature/fancy_ to _main_.

- Either via the Gitea UI (Open a pull request)
- or via the command line:
```
git checkout main
git merge feature/fancy
git push
```

A push into the main branch trigger the ansible pipeline.

#### Step 6: Check the pipeline for errors

If ansible-lint runs successfully the pipeline will automatically merge
the code from the _main_ branch into into _development_ and trigger a run of the _Pipeline - SOE - Development hosts_ template.

If the job succeeds successfully the pipeline creates a merge request
into production.

#### Step 7: Check if a merge request into production is available

If the pipeline run triggered in Step 5 is successful the pipeline
will automatically open a merge request to production.

### Step 8: Remove the feature branch

Execute

```
git push origin :feature/fancy
```

to remove the feature branch we created in Step 2. This will delete the branch
in the remote Gitea repository.

```
git branch -d feature/fancy
```

will remove the branch locally.

### Step 9: Confirm feature environment got removed from Ansible Controller

Confirm going back to the Ansible Controller web UI, the job template _Pipeline - SOE - Development hosts_ and the project


## Possible improvements to the pipeline

- Work with collections and Automation Hub
  - Same workflow, create feature branch in collection repo
  - Test feature branch via pipeline and/or Controller jobs
  - Merge feature to main and release
- Extend testing of playbooks
  - Use [molecule](https://molecule.readthedocs.io/en/latest/index.html) in the pipeline
  - Use [ServerSpec](https://serverspec.org/) or [goss](https://github.com/goss-org/goss) to spec-test configuration changes
- Use [Red Hat OpenShift Dev Spaces](https://developers.redhat.com/products/openshift-dev-spaces/overview) for providing a pre-configured developer environment
- Deploy temporary virtual machines for playbook testing with [OpenShift Virtualization](https://www.redhat.com/en/technologies/cloud-computing/openshift/virtualization)
  - Deploy machines when pushing a new feature branch, remove machines when feature branch gets deleted

## setup.yml options

```
gitea_skip_gitea: [yes|no] Skip Gitea setup
controller_subscription_installed: [yes|no] Does the Ansible Automation Controller have a valid subscription?
```

## Tips and Tricks

### Reset the password of the gitea `developer` user

```
oc exec -n gitea gitea-0 -- gitea  admin user change-password --username developer --password pipeline
```
