# AWS Terraform MVP - File Storage Microservice

![Terraform](https://img.shields.io/badge/Terraform-IaC-blueviolet?logo=terraform)
![AWS](https://img.shields.io/badge/AWS-Cloud-orange?logo=amazon-aws)
![EC2](https://img.shields.io/badge/AWS-EC2-orange?logo=amazon-aws)
![S3](https://img.shields.io/badge/AWS-S3-green?logo=amazon-s3)
![RDS](https://img.shields.io/badge/AWS-RDS-blue?logo=amazon-rds)
![Python](https://img.shields.io/badge/Python-Flask-blue?logo=python)

This project demonstrates a fully automated **Infrastructure-as-Code (IaC) deployment** of a minimal but realistic **file-storage microservice** on AWS using Terraform.  
The solution provisions a secured network environment, a Flask-based web application running on EC2, an S3 bucket for object storage, and an RDS MySQL database, all integrated through IAM roles and security groups.

This MVP illustrates how cloud microservices are typically designed:  
a **frontend/API layer**, a **storage layer**, and an **optional database layer**, deployed in a structured VPC environment following AWS best practices.

---

## 1. What This Microservice Does

The deployed application provides two core capabilities:

1. **Upload files to S3** (via a Flask web interface)  
2. **Download files from S3** by filename  

It demonstrates how a simple EC2-hosted microservice can interact with AWS-managed services securely and programmatically using IAM roles and least-privilege principles.

The application is automatically deployed by a `user_data` script, meaning **no manual configuration** is required after Terraform provisions the infrastructure.

---

## Why Some AWS Services Are Not Included

This MVP intentionally focuses on a minimal set of AWS services (VPC, EC2, S3, RDS, IAM) to demonstrate core cloud architecture principles while staying fully within the **AWS Free Tier**.  
Services such as ALB, Auto Scaling, Secrets Manager, CloudFront, or EFS were **not** included—not because they were overlooked, but because:

- they are **outside** the scope of the Free Tier  
- they incur **additional costs** even at minimal usage  
- they are **not required** to demonstrate the core design pattern of a microservice architecture  
- the goal of this MVP is to provide a **cost-efficient, fully functional, educational** deployment  

This ensures that anyone reviewing or reproducing the project can deploy it safely without incurring unexpected AWS charges.

---

## 2. AWS Components Explained

### **Virtual Private Cloud (VPC)**
The VPC is the foundational network boundary for all deployed infrastructure.  
It provides:
- A `/16` address space  
- **1 public subnet** for the EC2 instance  
- **2 private subnets** (distributed across two AZs) for RDS  
- Routing tables and an Internet Gateway  
This isolates public-facing components from backend services and follows standard cloud architecture patterns.

---

### **EC2 Instance (Flask Web App)**
A lightweight Ubuntu server running:
- A Python Flask microservice  
- Automatic deployment via `user_data`  
- IAM Instance Profile granting S3 + CloudWatch permissions  

It acts as the **frontend/API layer**, enabling users to upload and download files.

---

### **S3 Bucket**
A secure object storage backend used by the microservice.  
Configured with:
- `BucketOwnerEnforced` (ACLs disabled)  
- Default AES-256 encryption  
- Versioning enabled  
- Public access fully blocked  

It stores all uploaded files and returns them on request.

---

### **RDS MySQL Database**
A private database deployed across two private subnets (as required by AWS).  
Although not strictly required for file storage, it demonstrates how:
- Microservices often track metadata  
- Backend databases should be isolated in private networks  
- EC2-only access is enforced via security groups  

---

### **IAM Roles & Policies**
IAM ensures the microservice accesses only what it needs:
- EC2 can read/write S3  
- EC2 can send logs/metrics to CloudWatch  
No access keys are stored on the server as it relies entirely on **instance metadata credentials**.

---

### **Security Groups**
Network firewalls controlling service-to-service communication:
- **EC2 SG:**  
  - Allow HTTP from anywhere  
  - Allow SSH only from your IP  
- **RDS SG:**  
  - Allow MySQL traffic **only from the EC2 SG**  
This enforces strict segmentation between tiers.

---

## 3. How the Components Connect (High Level)

The architecture works as follows:

1. **User → EC2 Web App**  
   User uploads or downloads files via Flask.

2. **EC2 → S3**  
   EC2 uses its IAM role to interact with the S3 bucket securely.

3. **EC2 → RDS** (optional)  
   EC2 could store metadata or application state in MySQL.

4. **VPC + Subnets**  
   Ensure proper isolation:
   - Public subnet for EC2  
   - Private subnets for RDS  
   - No public access to S3 or RDS  

5. **Security Groups & IAM**  
   Enforce least-privilege access and allow only necessary communication.

---

## 4. Architecture Diagram

The diagram below illustrates the complete flow of the microservice, including networking, compute, storage, IAM, and optional monitoring.

It shows how users interact with the web application, how the EC2 instance communicates with S3 and RDS, and how IAM + Security Groups enforce secure access.

### **Architecture Overview**
![Architecture Diagram](images/architecture-mvp.png)

---

## 4.1 How the Architecture Works (End-to-End Request Flow)

This section explains the complete lifecycle of a user request, following the flow illustrated in the diagram.

### **1. User → Internet → VPC Public Subnet**
A user connects to the public IP or DNS of the EC2 instance from a web browser.  
The request flows through:

**User → Internet → AWS Internet Gateway (IGW) → Public Route Table → EC2 Instance**

The EC2 Security Group allows:
- HTTP (TCP 80) from anywhere  
- SSH (TCP 22) only from your IP  

The Internet Gateway provides connectivity exclusively for resources inside the public subnet.

---

### **2. EC2 Instance (Flask Web Server) Receives and Processes the Request**
The Flask application running on EC2 handles two main actions:

- **`/upload`** → Accepts files and uploads them to S3  
- **`/download`** → Retrieves files from S3 and returns them to the user  

The instance has an attached **IAM Role (Instance Profile)**, which provides temporary AWS API credentials via the metadata service.  
No hard-coded keys or secrets are used.

---

### **3. EC2 → S3 Communication (File Storage Layer)**
When uploading or downloading files, the EC2 instance interacts with the S3 bucket:

- EC2 sends API requests to S3 using its IAM role  
- S3 receives the request, validates permissions, and stores or returns the object  
- The bucket is fully private; no public access is allowed  

Encryption, versioning, and owner-enforced controls ensure secure storage.

---

### **4. EC2 → RDS Communication (Optional Metadata Layer)**
If the application needs to store metadata or transactional data:

- EC2 connects to the **RDS MySQL DB** through the private network  
- The **RDS Security Group** allows MySQL (TCP 3306) **only from the EC2 Security Group**  
- RDS resides inside **two private subnets** with no internet route  

This maintains backend isolation and prevents external access.

---

### **5. VPC, Subnets, Route Tables, and Security Groups Enforce Isolation**
The architecture separates layers using network segmentation:

- **Public Subnet:** EC2 Web Server  
- **Private Subnets:** RDS Database  
- **No Internet Route:** Private route tables block external access  
- **Security Groups:** Restrict all east-west and north-south traffic  

IAM + Security Groups form the core of the environment’s zero-trust posture.

---

### **6. Logging & Monitoring (CloudWatch)**
The EC2 role also allows the instance to:

- Push application logs  
- Send system metrics  
- Support CloudWatch dashboards and alarms  

This provides operational visibility across the microservice.

---

### **Summary**
User requests reach the EC2 Web Server via the public subnet.  
The EC2 instance handles application logic and interacts securely with S3 and RDS through IAM and private networking, while VPC routing and Security Groups strictly control all communication flows.

---

## 5. Infrastructure Screenshots

This section provides visual verification of all deployed AWS resources created by Terraform.

### **VPC Overview**
Shows the VPC, subnets, route tables, and networking components provisioned by Terraform.

![VPC Overview](images/vpc-overview.png)

---

### **EC2 Instance Running**
Displays the EC2 instance running the Flask microservice, deployed in the public subnet.

![EC2 Instance Running](images/ec2-instance-running.png)

---

### **IAM Role for EC2**
Demonstrates the IAM role and the attached policies enabling EC2 → S3 and EC2 → CloudWatch interactions.

![IAM Role Summary](images/iam-role-ec2.png)

---

### **RDS Instance Summary**
Screenshot of the RDS MySQL instance running inside private subnets.

![RDS Instance Summary](images/rds-instance-summary.png)

---

### **S3 Bucket Overview**
Shows general S3 bucket configuration (private, encrypted, versioned).

![S3 Bucket Overview](images/s3-bucket-overview.png)

---

## 6. Microservice Web Application Screenshots

These screenshots demonstrate the fully functioning file-storage microservice deployed on the EC2 instance.

---

### **Web Application Homepage**
The landing page of the Flask microservice served by the EC2 instance.

![Web Application Homepage](images/webapp-homepage.png)

---

### **Upload Form — Client List CSV**
The upload interface for sending files to S3.

![Upload Form Client List](images/upload-form-client-list.png)

---

### **Upload Form — Cat Picture**
Second example showing image upload capability.

![Upload Form Cat Picture](images/upload-form-cat-pic.png)

---

### **Upload Success — Client List CSV**
Confirmation message after successfully uploading the CSV file.

![Upload Success Client List](images/upload-success-client-list.png)

---

### **Upload Success — Cat Picture**
Confirmation message after uploading the image.

![Upload Success Cat Picture](images/upload-success-cat-pic.png)

---

### **Download Success — Client List CSV**
The CSV file successfully retrieved from S3 using the microservice’s `/download` endpoint.

![Download Success Client List](images/download-success-client-list.png)

---

### **Download Success — Cat Picture**
Successful file retrieval of the test image.

![Download Success Cat Pic](images/download-success-cat-pic.png)

---

### **S3 Bucket Objects**
Displays uploaded files after using the microservice.

![S3 Bucket Objects](images/s3-bucket-objects.png)

---

### **RDS Table: Stored Upload Metadata**
To demonstrate the use of RDS within the microservice architecture, the application stores  
a simple metadata record in the `uploads` table for every file uploaded to S3.

Each record includes:
- the **filename**
- the **timestamp** of upload (as stored by the backend)

This confirms that:
- EC2 can successfully connect to the RDS instance in the private subnets  
- IAM & Security Groups are correctly configured to allow EC2 → RDS communication  
- The microservice uses the database in a practical, meaningful way  

Below is the screenshot showing the contents of the table, retrieved via SSH from the EC2 instance:

![RDS Uploads Table](images/rds-uploads-table.png)

---

## 7. Terraform Execution Proof (Validation, Plan, Apply)

This section demonstrates the full Infrastructure-as-Code lifecycle for deploying the MVP microservice on AWS.

---

### **Terraform Validate**
Ensures that the Terraform configuration is syntactically correct and internally consistent.

![Terraform Validate Success](images/terraform-validate-success.png)

---

### **Terraform Plan (Preview) — Part 1**
Shows the first part of the execution plan before provisioning resources.

![Terraform Plan Success 1](images/terraform-plan-success-1.png)

---

### **Terraform Plan (Preview) — Part 2**
Continuation of the plan output, showing creation steps for EC2, RDS, S3, IAM, and networking.

![Terraform Plan Success 2](images/terraform-plan-success-2.png)

---

### **Terraform Apply — Part 1**
Terraform begins provisioning AWS resources according to the architecture.

![Terraform Apply Success 1](images/terraform-apply-success-1.png)

---

### **Terraform Apply — Part 2**
Final confirmation that all resources were successfully created.

![Terraform Apply Success 2](images/terraform-apply-success-2.png)

---

## 8. Conclusion

This project demonstrates a complete, production-style AWS microservice implemented entirely through **Infrastructure-as-Code** using Terraform.  
It showcases how multiple AWS services, VPC networking, EC2, S3, RDS, IAM, and Security Groups, can be combined into a secure, modular, and fully automated architecture.

Key takeaways:

- The microservice was deployed **without manual configuration**, relying solely on Terraform provisioning and user_data automation.
- EC2 interacts securely with S3 and RDS using **IAM instance roles** and least-privilege access.
- The environment follows **AWS best practices**, including private subnets for databases, strict security group segmentation, encryption, and no public exposure of backend systems.
- Terraform Validate → Plan → Apply outputs provide full transparency and traceability of the deployed infrastructure.
- The Flask application demonstrates a real-world pattern: upload → store → retrieve, backed by S3 object storage.

This MVP forms a strong foundation for future enhancements such as:

- Load balancers (ALB)
- Auto Scaling Groups
- HTTPS with ACM + ALB
- CloudFront CDN
- Secrets Manager for DB credentials
- Containerizing the microservice (ECS or EKS)

With these components in place, the architecture can scale from a simple demonstration into a full enterprise-grade microservice.