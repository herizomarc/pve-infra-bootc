# 🛡️ Sovereign Zero-Touch RHEL 9 BootC & OpenTofu Proxmox Pipeline

[![RHEL 9 Image Mode](https://shields.io)](https://redhat.com)
[![OpenBao SSOT](https://shields.io)](https://openbao.org)
[![OpenTofu IaC](https://shields.io)](https://opentofu.org)
[![Proxmox VE](https://shields.io)](https://proxmox.com)
[![GitLab CI/CD](https://shields.io)](https://gitlab.com)

End-to-end **DevSecOps & GitOps Infrastructure-as-Code** factory that compiles an **immutable RHEL 9 Image Mode (`bootc`)** container, translates it into a bootable **QCOW2** virtual disk, and provisions sovereign appliances (such as **Zabbix 7.0 LTS**) onto **Proxmox VE** using **OpenTofu** and **Cloud-Init**—with **zero hardcoded secrets** and **zero disk writes** for credentials.

---

## 🏗️ Architecture & Workflow

```text
┌───────────────────┐     1. OIDC JWT Auth      ┌──────────────────────────┐
│   GitLab CI/CD    │ ────────────────────────► │      OpenBao (SSOT)      │
│  (Self-Hosted)    │ ◄──────────────────────── │  Ephemeral RAM Secrets   │
└─────────┬─────────┘   2. Volatile Tokens/Keys └──────────────────────────┘
          │
          ├─► [Stage 1: build-os]     Podman builds immutable RHEL 9 BootC OCI image
          ├─► [Stage 2: package-disk] bootc-image-builder converts OCI → bootable QCOW2
          └─► [Stage 3: deploy-infra] OpenTofu + ssh-agent (RAM) provisions Proxmox VE
                                              │
                                              ▼
                              ┌───────────────────────────────┐
                              │     Proxmox VE (UEFI/OVMF)    │
                              │  • scsi0: Immutable OS (raw)  │
                              │  • scsi1: Data Disk (XFS)     │
                              │  • scsi2: Cloud-Init Day-0    │
                              └───────────────────────────────┘
```

### Key Engineering Highlights

* **Zero-Trust Secret Management (OpenBao + OIDC):** GitLab runners authenticate dynamically via short-lived OIDC JWT tokens. Registry credentials and SSH private keys are loaded strictly into volatile memory (`/dev/shm` and `ssh-agent` sockets) and purged immediately after execution.
* **Immutable Operating System (RHEL 9 `bootc`):** Operating system packages, SELinux policies (`zabbix_can_network`, `httpd_can_connect_zabbix`), and agents (`cloud-init`, `qemu-guest-agent`) are declaratively compiled into an OCI image (`containers/zabbix.Containerfile`) for atomic, reproducible upgrades.
* **Zero-Touch Day-0 Initialization (`Cloud-Init`):** On first boot via `scsi2` (UEFI OVMF compatible), Cloud-Init automatically partitions the secondary data disk (`scsi1` → `/var/lib/pgsql`), generates a random PostgreSQL password in RAM, initializes the Zabbix schema, and pre-configures the web frontend.
* **Data-Driven Topology (`OpenTofu`):** Virtual machine sizing, VLAN/bridge attachments, and static IP allocations are decoupled into `terraform/terraform.tfvars` with remote state locking managed natively by GitLab HTTP Backend.

---

## 📂 Repository Structure

```text
.
├── .gitlab-ci.yml                 # 3-stage DevSecOps pipeline (Build OCI → QCOW2 → OpenTofu)
├── .gitignore                     # Hardened rules blocking states, images, and local keys
├── containers/
│   └── zabbix.Containerfile       # Immutable RHEL 9 BootC recipe + SELinux hardening
├── templates/
│   └── zabbix.yaml.tmpl           # Zero-touch Cloud-Init Day-0 bootstrapper (Disks, DB, Web UI)
└── terraform/
    ├── main.tf                    # Proxmox VE VM, snippet & LVM-Thin raw disk provisioning
    ├── providers.tf               # bpg/proxmox provider & GitLab HTTP remote backend
    ├── variables.tf               # Typed input definitions & sensitive secret bindings
    ├── terraform.tfvars           # Declarative appliance matrix (CPU, RAM, Storage, Network)
    └── outputs.tf                 # Deployed VM IDs and network metadata
```

---

## ⚙️ Prerequisites & Security Controls

1. **OpenBao Secrets Engine (KV v2):**
   * `secret/infrastructure/rhel-registry-entitlement` (`service_account_username`, `service_account_token`)
   * `secret/infrastructure/proxmox-credentials` (`api_token_id`, `api_token_secret`, `skey`)
   * `secret/infrastructure/secops-host-authentication` (`ed25519_public_key`)
2. **GitLab CI/CD Variables:** `BAO_ADDR`, `PVE_API_ENDPOINT`, `PVE_NODE_NAME`, `PVE_SSH_HOST`.
3. **Proxmox VE Storage:** `local` storage enabled for `iso` and `snippets`; `local-lvm` configured for `images` (`raw` format).

---

## 🚀 Deployment Lifecycle

1. **Modify OS or Infrastructure:** Update `containers/zabbix.Containerfile` for OS/package changes or `terraform/terraform.tfvars` for VM topology scaling.
2. **Push to `main`:** GitLab CI/CD automatically builds the OCI image, generates the QCOW2 disk, and applies the declarative state on Proxmox VE.
3. **Day-2 Atomic OS Upgrades:** Trigger `sudo bootc upgrade --apply` directly on running appliances to pull newly built OCI layers without reprovisioning data volumes (`/var/lib/pgsql`).
