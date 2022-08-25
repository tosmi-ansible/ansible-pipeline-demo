# Ansibel Pipeline Demo

This respository contains a demo that demonstrate how to

- Validate Ansible in an automated fashion
- Merging changes automatically to different repository branches after validation
- Trigger Ansible Controller jobs after merging

## Motivation

Using Ansible for automation is only a starting poing in a longer
journey. For most larger automation setups the following questions
arise after automating the first tasks:

- How can we test our Ansible code base before applying it to
  production system?
- Which tools are available for testing Ansible code?
- Is it possible to fully automate the whole workflow of testing
  Ansible code and bringing it to production?

Answering the questions above when starting with a blank page is
hard. There are multiple solutions and even more tools to achive the
desired result.

This Demo setup tries to answer some of these questions. We only
scratch the surface of what's acutally possible. It's not the
definitive answer but should help getting started without staring at a
blank page.

## Tools

We use the following tools to implement our pipeline

- [Gitea](https://gitea.io/en-us/):
  - Storing our Ansible code base and
  - our Ansible Controller configuration
- [Tektion](https://tekton.dev/) for implementing our pipeline
- [Ansible Controller](https://www.ansible.com/products/controller)
  for executing Ansible code
