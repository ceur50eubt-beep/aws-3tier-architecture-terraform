# Production-Grade AWS 3-Tier Architecture with Terraform
> **Enterprise Multi-AZ Infrastructure as Code (IaC) with Defense-in-Depth Security**

[![Terraform Security & Validate](https://github.com/ceur50eubt-beep/aws-3tier-architecture-terraform/actions/workflows/terraform_ci.yml/badge.svg)](https://github.com/ceur50eubt-beep/aws-3tier-architecture-terraform/actions/workflows/terraform_ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A production-ready, highly available, and secure 3-Tier Web Architecture on AWS provisioned entirely with **Terraform (IaC)**. Designed in compliance with the **AWS Well-Architected Framework**, featuring complete network segmentation, Multi-AZ fault tolerance, least-privilege security groups, and encryption-ready routing.

---

## 1. Architectural Highlights

* **Multi-AZ High Availability**: Deployed across multiple Availability Zones (ap-northeast-1a and 1c) to eliminate single points of failure (SPOF).
* **Strict Network Isolation (3-Tier Segmentation)**:
  * **Public Subnets**: Ingress traffic via Internet-facing ALB route table mapped to Internet Gateway (IGW).
  * **Private Application Subnets**: Compute/Container workloads isolated from public ingress.
  * **Isolated Database Subnets**: Completely non-routable subnets with zero internet gateway route, preventing any external data leakage.
* **Chained Security Groups (Zero Trust Layering)**:
  * Application layer strictly permits inbound traffic sourced from the ALB Security Group.
  * Database layer strictly permits inbound SQL traffic (PostgreSQL:5432, MySQL:3306) sourced from the Application Security Group.

---

## 2. Core Architecture

```text
                  [ Internet / End Users ]
                             │
                             ▼ (HTTPS :443)
              ┌──────────────────────────────┐
              │     Internet Gateway (IGW)   │
              └──────────────┬───────────────┘
                             │
      ================ VPC (10.0.0.0/16) =================
      │                                                  │
      │  [ Public Subnets ] (AZ-1a / AZ-1c)              │
      │  ┌────────────────────────────────────────────┐  │
      │  │        Application Load Balancer (ALB)     │  │
      │  └──────────────┬─────────────────────────────┘  │
      │                 │                                │
      │                 ▼ (Port 8080 - Chained SG)       │
      │  [ Private App Subnets ] (AZ-1a / AZ-1c)         │
      │  ┌────────────────────────────────────────────┐  │
      │  │   Compute Layer (ECS Fargate / EC2 ASG)    │  │
      │  │   - Multi-AZ High Availability             │  │
      │  └──────────────┬─────────────────────────────┘  │
      │                 │                                │
      │                 ▼ (Port 5432/3306 - Chained SG)  │
      │  [ Isolated DB Subnets ] (AZ-1a / AZ-1c)         │
      │  ┌────────────────────────────────────────────┐  │
      │  │   Amazon Aurora / RDS Multi-AZ             │  │
      │  │   - Primary (Writer) ──▶ Replica (Reader)  │  │
      │  │   - Zero Internet Route (Isolated Table)   │  │
      │  └────────────────────────────────────────────┘  │
      ====================================================
```

---

## 3. Directory Structure

```text
aws-3tier-architecture-terraform/
├── README.md
├── vpc.tf                             # Multi-AZ VPC, Subnets, IGW, and Route Tables
├── security_group.tf                  # Chained Security Groups (ALB -> App -> DB)
└── .github/
    └── workflows/
        └── terraform_ci.yml           # Automated fmt check & validation CI pipeline
```

---

## 4. Verification & Deployment

```bash
# Initialize Terraform
terraform init

# Validate configuration format and syntax
terraform fmt -check
terraform validate

# Plan provisioning
terraform plan
```

---

## 5. SRE & Compliance Takeaways

* **Deterministic Blast Radius**: Network segmentation guarantees that a compromise in the public ingress tier cannot reach the database tier directly.
* **Audit-Ready IaC**: Complete declarative state ensures reproducibility across staging and production environments without configuration drift.
