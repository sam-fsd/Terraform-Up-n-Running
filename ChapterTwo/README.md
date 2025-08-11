# Terraform Web Server Deployment

## Overview
This project demonstrates progressive web server deployment using Terraform, starting with a single server and scaling to multiple servers with load balancing.

## Project Phases

### Phase 1: Single Web Server
- Deploy one web server instance
- Basic networking and security configuration

### Phase 2: Multiple Web Servers  
- Deploy 2-3 web servers
- Configure server cluster
- Implement load balancer

## Architecture Evolution

**Current: Single Server**
```
┌─────────────┐
│ Web Server  │
└─────────────┘
```

**Target: Load Balanced Cluster**
```
    ┌──────────────┐
    │ Load Balancer│
    └──────┬───────┘
           │
    ┌──────┴───────┐
    │              │
┌───▼───┐    ┌─────▼──┐
│Server 1│    │Server 2│
└────────┘    └────────┘
```

## Getting Started

1. **Initialize Terraform**
   ```bash
   terraform init
   ```

2. **Plan Deployment**
   ```bash
   terraform plan
   ```

3. **Deploy Infrastructure**
   ```bash
   terraform apply
   ```

4. **Destroy When Done**
   ```bash
   terraform destroy
   ```

## Project Structure
```
Project-Deploy/
├── README.md
├── main.tf
├── variables.tf
├── outputs.tf
└── terraform.tfvars
```

## Configuration
Create `terraform.tfvars` with your settings:
```hcl
instance_type = "t3.micro"
server_count  = 1  # Will increase in later phases
```

---
*Each phase will have its own detailed implementation in separate directories.*