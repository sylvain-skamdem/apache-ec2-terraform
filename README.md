# 🚀 Deploy Apache on EC2 Using Terraform & User Data

> **Lab Exercise** — Launch an Amazon EC2 instance, auto-configure Apache via User Data, set a custom hostname, display a custom webpage, and connect via PuTTY — all provisioned with Terraform from VS Code.

---

## 📋 Table of Contents

1. [Project Overview](#-project-overview)
2. [Architecture Diagram](#-architecture-diagram)
3. [Prerequisites](#-prerequisites)
4. [Project Structure](#-project-structure)
5. [Setup: AWS Credentials in VS Code](#-setup-aws-credentials-in-vs-code)
6. [Setup: Key Pair for PuTTY](#-setup-key-pair-for-putty)
7. [Deployment Steps](#-deployment-steps)
8. [Connect via PuTTY](#-connect-via-putty)
9. [Verify the Webpage](#-verify-the-webpage)
10. [Verify Inside the Instance](#-verify-inside-the-instance)
11. [Outputs Reference](#-outputs-reference)
12. [Teardown](#-teardown)
13. [Troubleshooting](#-troubleshooting)
14. [Lab Objectives Checklist](#-lab-objectives-checklist)

---

## 📌 Project Overview

This lab exercise provisions a fully functional Apache web server on AWS EC2 using infrastructure-as-code. The entire server configuration — package installation, hostname assignment, and custom webpage creation — happens automatically through EC2 **User Data** at launch time, with no manual SSH setup required.

| Item | Value |
|---|---|
| Cloud Provider | AWS |
| IaC Tool | Terraform ≥ 1.3.0 |
| OS | Amazon Linux 2 |
| Web Server | Apache (httpd) |
| Instance Type | t2.micro (Free Tier eligible) |
| Hostname | `Myfirstwebserver` |
| Webpage Message | `Hello from Myfirstwebserver` |
| SSH Client | PuTTY (Windows) |

---

## 🏗 Architecture Diagram

```
┌─────────────────────────────────────────────────┐
│                  AWS Cloud (us-east-1)           │
│                                                  │
│  ┌──────────────────────────────────────────┐    │
│  │           Security Group: web-server-sg  │    │
│  │   Inbound:  Port 22  (SSH)  0.0.0.0/0   │    │
│  │   Inbound:  Port 80  (HTTP) 0.0.0.0/0   │    │
│  │   Outbound: All traffic                  │    │
│  │                                          │    │
│  │  ┌────────────────────────────────────┐  │    │
│  │  │  EC2 Instance (t2.micro)           │  │    │
│  │  │  AMI: Amazon Linux 2              │  │    │
│  │  │  Hostname: Myfirstwebserver       │  │    │
│  │  │                                   │  │    │
│  │  │  User Data runs at boot:          │  │    │
│  │  │   • yum install httpd             │  │    │
│  │  │   • hostnamectl set-hostname      │  │    │
│  │  │   • Creates index.html            │  │    │
│  │  │   • systemctl enable/start httpd  │  │    │
│  │  └────────────────────────────────────┘  │    │
│  └──────────────────────────────────────────┘    │
└─────────────────────────────────────────────────┘
         ▲                        ▲
         │ Port 22 (PuTTY/SSH)    │ Port 80 (Browser)
         │                        │
    Your PC (Windows)        Your Browser
    VS Code + Terraform       http://<public-ip>
```

---

## ✅ Prerequisites

Before you begin, ensure the following are installed and configured on your Windows PC:

### Required Software

| Tool | Purpose | Download |
|---|---|---|
| **VS Code** | IDE for editing and running Terraform | [code.visualstudio.com](https://code.visualstudio.com) |
| **Terraform** | Infrastructure as Code CLI | [developer.hashicorp.com/terraform/downloads](https://developer.hashicorp.com/terraform/downloads) |
| **AWS CLI** | Authenticate Terraform with AWS | [aws.amazon.com/cli](https://aws.amazon.com/cli/) |
| **PuTTY** | SSH client for Windows | [putty.org](https://www.putty.org/) |
| **Git** | Version control / push to GitHub | [git-scm.com](https://git-scm.com/) |

### VS Code Extensions (Recommended)

Install these from the VS Code Extensions panel (`Ctrl+Shift+X`):

- **HashiCorp Terraform** — syntax highlighting & autocompletion
- **AWS Toolkit** — AWS resource browser inside VS Code

### AWS Account Requirements

- An active AWS account
- IAM user or role with permissions: `EC2FullAccess`, `VPCFullAccess`
- An existing **EC2 Key Pair** (`.pem` file) in your target region

---

## 📁 Project Structure

```
apache-ec2-terraform/
│
├── terraform/
│   ├── main.tf              # EC2 instance, Security Group, User Data
│   ├── variables.tf         # Input variable definitions
│   ├── outputs.tf           # Public IP, URL, SSH command
│   └── terraform.tfvars     # ⚠️ Your values (excluded from Git)
│
├── .gitignore               # Excludes state files, keys, tfvars
└── README.md                # This document
```

---

## 🔐 Setup: AWS Credentials in VS Code

Terraform needs AWS credentials to provision resources. Configure them using the AWS CLI:

### Step 1 — Open the VS Code Terminal
Press **`` Ctrl+` ``** to open the integrated terminal.

### Step 2 — Configure AWS CLI
```bash
aws configure
```
Enter when prompted:
```
AWS Access Key ID:     <your-access-key-id>
AWS Secret Access Key: <your-secret-access-key>
Default region name:   us-east-1
Default output format: json
```

Credentials are saved to `~/.aws/credentials` and are automatically picked up by Terraform.

> 💡 **Tip:** For better security, use AWS IAM Identity Center (SSO) or environment variables instead of long-lived access keys.

---

## 🔑 Setup: Key Pair for PuTTY

You need an EC2 Key Pair to connect via PuTTY. Follow these steps:

### Step 1 — Create a Key Pair in AWS Console

1. Open **AWS Console → EC2 → Key Pairs**
2. Click **Create key pair**
3. Name it (e.g., `my-keypair`)
4. Select **RSA** type
5. For PuTTY on Windows, select format: **`.ppk`**
6. Click **Create** — the `.ppk` file downloads automatically

> ⚠️ Save the `.ppk` file securely. You cannot download it again.

### Step 2 — Update terraform.tfvars

Open `terraform/terraform.tfvars` and set your key pair name:
```hcl
key_pair_name = "my-keypair"   # Must match the name in AWS Console
```

---

## 🚀 Deployment Steps

All commands are run in the **VS Code integrated terminal** from the `terraform/` directory.

### Step 1 — Clone the Repository
```bash
git clone https://github.com/<your-username>/apache-ec2-terraform.git
cd apache-ec2-terraform/terraform
```

### Step 2 — Initialize Terraform
Downloads the AWS provider plugin.
```bash
terraform init
```

Expected output:
```
Terraform has been successfully initialized!
```

### Step 3 — Validate Configuration
Checks for syntax errors without contacting AWS.
```bash
terraform validate
```

Expected output:
```
Success! The configuration is valid.
```

### Step 4 — Preview the Plan
Shows exactly what Terraform will create — no changes yet.
```bash
terraform plan
```

You should see **3 resources to add**: the AMI data source, security group, and EC2 instance.

### Step 5 — Apply (Deploy)
Creates all AWS resources.
```bash
terraform apply
```
Type `yes` when prompted to confirm.

```
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:

instance_id  = "i-0abc123def456789"
public_ip    = "54.123.45.67"
public_dns   = "ec2-54-123-45-67.compute-1.amazonaws.com"
website_url  = "http://54.123.45.67"
ssh_command  = "ssh -i <your-key.pem> ec2-user@54.123.45.67"
```

> ⏱ Wait **60–90 seconds** after apply for User Data to finish configuring Apache before opening the URL.

---

## 🖥 Connect via PuTTY

### Step 1 — Get the Public IP
Copy the `public_ip` value from the Terraform outputs, or run:
```bash
terraform output public_ip
```

### Step 2 — Open PuTTY

1. Launch **PuTTY**
2. In **Host Name (or IP address)**, enter: `ec2-user@<public-ip>`
3. Port: `22`, Connection type: `SSH`

### Step 3 — Load Your Private Key

1. In the left panel, navigate to **Connection → SSH → Auth → Credentials**
2. Click **Browse** next to *Private key file for authentication*
3. Select your `.ppk` file

### Step 4 — Save the Session (Optional)

1. Go back to **Session** in the left panel
2. Enter a name under *Saved Sessions* (e.g., `Myfirstwebserver`)
3. Click **Save**

### Step 5 — Connect

Click **Open**. Accept the host key fingerprint if prompted.

You should see the Amazon Linux 2 shell:
```
       __|  __|_  )
       _|  (     /   Amazon Linux 2 AMI
      ___|\___|___|

[ec2-user@Myfirstwebserver ~]$
```

> ✅ Notice the prompt shows **Myfirstwebserver** — confirming the hostname was set by User Data.

---

## 🌐 Verify the Webpage

1. Copy the `website_url` output from Terraform
2. Open any web browser
3. Navigate to `http://<public-ip>`

You should see:

```
┌─────────────────────────────────────────┐
│                                         │
│      Hello from Myfirstwebserver        │
│                                         │
│  Deployed automatically via Terraform   │
│           & EC2 User Data               │
│                                         │
└─────────────────────────────────────────┘
```

---

## 🔍 Verify Inside the Instance

After connecting via PuTTY, run these commands to verify the setup:

```bash
# Confirm the hostname
hostname
# Expected: Myfirstwebserver

# Check Apache service status
sudo systemctl status httpd
# Expected: active (running)

# View the User Data log (to confirm it ran)
sudo cat /var/log/cloud-init-output.log | tail -20

# View the custom webpage content
cat /var/www/html/index.html

# Test the web server locally from the instance
curl http://localhost
```

---

## 📤 Push to GitHub

### First-time setup

```bash
# From the project root (apache-ec2-terraform/)
git init
git add .
git commit -m "Initial commit: Apache EC2 Terraform lab"
git branch -M main
git remote add origin https://github.com/<your-username>/apache-ec2-terraform.git
git push -u origin main
```

### Subsequent pushes

```bash
git add .
git commit -m "describe your change"
git push
```

> ⚠️ `terraform.tfvars`, `*.tfstate`, `*.pem`, and `*.ppk` files are in `.gitignore` and will **not** be pushed to GitHub. Never commit credentials or state files.

---

## 📊 Outputs Reference

| Output | Description | Example |
|---|---|---|
| `instance_id` | AWS EC2 Instance ID | `i-0abc123def456789` |
| `public_ip` | Public IP address | `54.123.45.67` |
| `public_dns` | Public DNS hostname | `ec2-54-123-45-67...` |
| `website_url` | Full URL to the webpage | `http://54.123.45.67` |
| `ssh_command` | SSH command (Linux/macOS) | `ssh -i key.pem ec2-user@...` |

Retrieve any output at any time:
```bash
terraform output           # All outputs
terraform output public_ip # Single output
```

---

## 🗑 Teardown

To avoid ongoing AWS charges, destroy all resources when done:

```bash
terraform destroy
```

Type `yes` to confirm. All created resources (EC2 instance and security group) will be deleted.

---

## 🛠 Troubleshooting

| Problem | Likely Cause | Solution |
|---|---|---|
| `terraform init` fails | No internet / wrong provider version | Check internet connection; verify `required_providers` block |
| `Error: No valid credential sources` | AWS CLI not configured | Run `aws configure` |
| `InvalidKeyPair.NotFound` | Wrong key pair name in tfvars | Verify the name matches exactly in EC2 → Key Pairs |
| Page doesn't load after apply | User Data still running | Wait 90 seconds and refresh |
| PuTTY: `No supported authentication methods` | Wrong `.ppk` file or wrong username | Use `ec2-user` and verify the `.ppk` matches the key pair |
| Apache not running | User Data script error | SSH in and check `sudo systemctl status httpd` and `/var/log/cloud-init-output.log` |
| Port 80 refused | Security group missing | Verify the security group has inbound TCP 80 from `0.0.0.0/0` |

---

## ✔ Lab Objectives Checklist

- [ ] Launch an Amazon EC2 instance via Terraform
- [ ] Use EC2 User Data to install and start Apache automatically
- [ ] Set the server hostname to `Myfirstwebserver`
- [ ] Display a custom webpage: **"Hello from Myfirstwebserver"**
- [ ] Connect to the instance via PuTTY
- [ ] Verify the webpage from a web browser
- [ ] Push project to GitHub (excluding sensitive files)
- [ ] Destroy resources after the lab

---

## 📚 Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Amazon EC2 User Data Guide](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html)
- [PuTTY Documentation](https://www.chiark.greenend.org.uk/~sgtatham/putty/docs.html)
- [AWS Free Tier](https://aws.amazon.com/free/)

---

*Lab exercise — Infrastructure as Code with Terraform on AWS*
