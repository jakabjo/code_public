# Epic Proof of Concept (POC) – Microsoft Azure

## Overview
This repository contains modular Terraform scripts to deploy a secure and compliant **Epic Proof of Concept (POC)** in **Microsoft Azure**.
The goal is to validate **Epic EHR infrastructure performance, scalability, and compliance** on Azure while maintaining **HIPAA** and **HITRUST** standards.

This POC provides a representative simulation of Epic components such as **IRIS Cache**, **Hyperspace**, and **Interconnect**, enabling healthcare provider teams to benchmark performance, evaluate costs, and verify compliance alignment before broader adoption.

## Objectives
- Establish a secure **Azure landing zone** tailored for healthcare compliance.
- Deploy representative Epic components (infrastructure only) using Microsoft Azure services.
- Validate I/O performance, latency, and throughput using **Azure Premium SSD v2** or **Ultra Disks**.
- Implement **HIPAA/HITRUST controls**, Azure Policy enforcement, and centralized monitoring.
- Deliver a reproducible, modular Terraform framework for future scaling.

## Architecture Summary
The Terraform code provisions:
- **Resource Groups** segmented as `core`, `network`, `data`, `security`, and `logs`.
- **Networking**: VNet with subnets (`core`, `app`, `data`, `mgmt`, `gw`), NSGs, optional VPN gateway.
- **Storage**: Private-only **Storage Account** with **Private Endpoint** and **Private DNS** zones.
- **Security**: **Key Vault**, **Defender for Cloud** baseline, and **Azure Policy** tag governance.
- **Monitoring**: **Log Analytics** workspace integrated with resources.
- **Compute**: Windows Server VM sized for IRIS testing with configurable Premium/Ultra data disks.

## Repository Structure
```
epic-azure-poc/
├─ main.tf
├─ providers.tf
├─ versions.tf
├─ variables.tf
├─ outputs.tf
├─ env/
│  ├─ dev.tfvars
│  └─ prod.tfvars
└─ modules/
   ├─ resource_group/
   ├─ network/
   ├─ private_dns/
   ├─ storage_account/
   ├─ key_vault/
   ├─ log_analytics/
   ├─ defender_baseline/
   ├─ policy_baseline/
   ├─ windows_vm/
   └─ vpn_gateway_optional/
```

## Deployment
1. Initialize:
   ```bash
   terraform init
   ```
2. Validate and plan:
   ```bash
   terraform validate
   terraform plan -var-file="env/dev.tfvars"
   ```
3. Apply:
   ```bash
   terraform apply -var-file="env/dev.tfvars"
   ```

## Notes for the Epic POC
### Performance and Configuration
- Epic IRIS and Hyperspace workloads are I/O sensitive. Use **Premium SSD v2** or **Ultra Disk** for realistic tests.
- Start with `Standard_D8s_v5` or `Esv5` VM sizes, then tune per benchmark results.
- Use Epic-approved test harnesses or Iometer-style tools to validate latency and throughput.

### Compliance
- All resources adhere to security and compliance baselines.
- Deployed services map to Microsoft’s **HIPAA** and **HITRUST** compliant offerings.
- Use **synthetic** data only in the POC. No production PHI should be stored or transmitted.

### Integration
- The optional VPN gateway module provides a stub for hybrid connectivity to simulate on‑prem Epic integration.
- For production, consider **ExpressRoute** and dedicated private connectivity.

### Monitoring and Reporting
- **Log Analytics** captures metrics for latency, IOPS, CPU, and network performance.
- Extend with **Azure Monitor** and **Application Insights** for deeper telemetry.

### Security
- **Key Vault** stores secrets and certificates.
- **Defender for Cloud** and **Policy Baseline** enforce least privilege and tagging.
- Prefer **Azure Bastion** or a private jump server for RDP and administrative access.

## Success Criteria
- POC meets or exceeds on‑prem baselines for target Epic tests.
- All resources align with **HIPAA** and **HITRUST CSF v11** requirements.
- Documentation demonstrates scalability, reliability, and cost transparency.

## Attribution
This framework was developed by the **Azure Cloud Delivery Team** to support evaluation of Epic EHR workloads in Azure.
It aligns with **Microsoft Cloud Adoption Framework**, **Azure Well‑Architected Framework**, and Epic reference guidance.
