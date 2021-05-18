# deploy_vm

Deploying one of virtual machines

## Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with deploy_vm](#setup)
    * [Setup requirements](#setup-requirements)
    * [Beginning with deploy_vm](#beginning-with-deploy_vm)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Limitations - OS compatibility, etc.](#limitations)
1. [Development - Guide for contributing to the module](#development)

## Description

The deploy_vm module provides a Bolt plan that facilitates the simple deployment
of one off virtual machines through to use of a basic and mostly static
Terraform manifest for each target provider.

## Setup

### Setup Requirements

Module requires that the host for which the plan is ran from has appropriate
network access and credentials for deployment to target provider and the ability
to authenticate to the new virtual machine to ensure it is really fully deploed
and accepting remote connections.

Terraform must also be installed in a location that is included in the path of
the operating system executing the plan.

### Beginning with deploy_vm

Add these two modules to your PE codebase or Bolt Project

```
mod 'ody-deploy_vm',
  git: 'https://github.com/ody/ody-deploy_vm.git',
  ref: 'main'
mod 'puppetlabs-terraform', '0.6.1'
```

## Usage

### Example: Using the PE cli interface launch a virtual machine on GCP using the PE primary server as the initiating host

Targets in this context is the host that the PE orchestrator will launch the plan from

`puppet plan run deploy_vm targets=pe-primary.example.com ssh_user=provisioner network=default provider=gcp vm_name=example`

## Limitations

By design, throws away any state generated during the run of Terraform. This is
specifically so that additional provisioning tools do not need to be maintained
which would provide more maintenance burden then value. Currently only launches
a single VM per invocation.

## Development

The plan as part of the module MUST function on Puppet Enterprise, a core use
case being the ability to trigger a virtual machine deployment via an API call
from other systems.