3DAdapt AWS Deployment
======================

This repo is for notes, scripts, and packages for installing [3DAdapt](https://github.com/MoravianUniversity/3DAdapt) on AWS. This primarily utilizes EC2 and S3 services.


AWS Components and Costs
------------------------

A basic AWS deployment requires the following (all prices assume US East (N. Virginia) region as of August 2023):
* **EC2 instance:** t4g.small (2 CPUs, 2 GB RAM) is probably sufficient for an initial deployment or if the Celery server is on a separate, larger, machine (the background tasks are much more intensive than the web server itself)
  * Estimated cost: $12.27/month (it may be able to test on the free tier t2.micro, but not recommended for production)
    * With a savings plan it could be as low as $5.57/month
  * Since this serves all website and API data, it also costs for the data transfer
    * Estimated cost: $0.18/month (estimating 2 GB/month) (eligible for free tier)
* **EBS storage:** at least 5 GB (2 GB for the base OS, 1 GB for the software, 1 GB for nginx, and 1 GB for the background task storage)
  * Estimated cost: $0.40/month (eligible for free tier)
* **S3 buckets:** for storing uploaded images and files
  ~2500 files taking up ~800MB and ~5000 images taking up ~450M (with symlinks) to 900M, 50% of both are likely infrequently access
  * No need for intelligent tiering since only 2GB of data in lots of small objects, any savings produced would be negated by the costs
  * Estimated cost: $0.05/month for storage, $0.92/month for retrieval (50k requests, 10GB data), and $0.04 for initial uploading (eligible for free tier)
  * Adding CloudFront CDN may be able to reduce costs as well and can provide additional features:
    * The retrieval costs would be reduced to $0.90/month so not much different for the assumed values here, but could make a difference in other situations
* **SES email** server for outgoing mail (3000/month, 8 KB each)
  * Estimated cost: less than $0.51/month (partially eligible for free tier)
* Optional: SES email server for incoming un-subscription requests (100/month, <1 KB each)
  * Estimated cost: less than $0.02/month (partially eligible for free tier)
  * Note: very few regions support SES receiving (i.e. un-subscription requests), there are workarounds for this
  * May need to use of SNS and SQS alongside SES, but this is free (as long as there is less than 1 million requests/month)
* **MongoDB-Atlas database server:**
  * Signup at (mongodb.com/pricing)[https://www.mongodb.com/pricing]
  * The free shared server likely is sufficient, eventually may want serverless though
* **Hosted Zone:**
  * Each zone (domain) is $0.50/month plus a small amount based on the number of DNS requests (<$0.10/month)
  * Each domain costs annual registration fees depending on the domain, this value is not included here

Total estimated cost: ~$15/month (dominated by EC2 instance, with savings plan could be less than $10/month)

Setup
-----
Make sure all things are set up in the same region (e.g. US East (N. Virginia)).

* **Optional: Hosted Zone Setup:**
  * If registering your domain through Amazon, this should be done at the same time as setting up the hosted zone
  * In Route 53, go to hosted zones and create a hosted zone, set up the domain as necessary (will not be able to add the main CNAME until the EC2 instance has an IP though)
  * Advantages of Route 53:
    * Easier SES verification
    * Easier automatic SSL certificate creation
  * Advantages of Cloudfront:
    * Free (as opposed to $0.50+/month)
    * Free and built in basic caching (instead of using AWS CloudFront)
    * Free basic email forwarding
* **MongoDB Setup:**
  * Sign up for the service at (mongodb.com/cloud/atlas/register)[https://www.mongodb.com/cloud/atlas/register]
  * Create a database (free tier is sufficient) with a user that has read/write access to the database
  * Add the IP address of the EC2 instance (once you get it) to the IP access list
  * Get the connection string and save it somewhere safe
* **S3 Setup:** Create 3 buckets: one for images, one for files, and one for private configuration data
  * For configuration:
    * Use default settings
  * For images and files:
    * Technically, these can be the same bucket, but it is easier to separate them for certain settings
    * Make sure the bucket names do not include `.` (it prevents HTTPS links from working; in the future, one solution to this is to use CloudFront, but that isn't available in the code yet).
    * Make sure to uncheck all things that may block public access and confirm it is okay
    * Choose ACLs enabled for object ownership, keep bucket owner preferred option
    * Once created:
      * Edit the permissions of each to add the read option to the "Everyone (public access)" ACL group
      * Add a bucket policy with the following (updating the `<bucket-name>` as appropriate):
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicRead",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "s3:GetObject",
                "s3:GetObjectVersion"
            ],
            "Resource": "arn:aws:s3:::<bucket-name>/*"
        }
    ]
}
```
* **SES Setup:**
  * On the SES Dashboard, choose SMTP settings and choose "Create SMTP credentials". Follow the steps to create the SMTP user, make sure to save the username and password for later.
  * On the SES Dashboard, choose Configuration Sets and the Create Set
    * Name: default
    * Recommended to enable Reputation metrics
  * Go to Identities and Create Identity
    * Type: domain, enter your domain, assign the default configuration set
    * Then create and verify it (while you are at it, set up DMARC rules on the domain)
      * If you are using Route 53, the verification process is somewhat automatic, if using another service you will have to create the DNS records manually
  * Create another identity for your personal email (not the domain being set up), this allows sending test emails and getting into production
  * Go to "Get set up" and under "Get production access" it should now have a verified email address and verified sending domain; finish with sending a test email.
  * Return to "Get set up" and request "Production" to move out of the Sandbox
* **IAM Setup:**
  * Go to the IAM Dashboard
  * Go to Policies and create a policy named "EC2-access" with the following JSON contents in `ec2/ec2-access.json` (updating the bucket names and hosted zone id as appropriate)
  * go to Roles and create a new role
    * Trusted entity type: AWS service
    * Choose EC2 service and use case
    * Find and select the EC2-access policy created above
    * Name the role ec2-access
  * You may also want to create a user with this policy as well (for on-premises testing)
    * Under the new user's Security Credentials, create an access key and secret key (you will need to save the access and secret keys somewhere safe)
* **EC2 Setup:**
  * Make sure you create and save a key pair when you first launch an instance
  * Compile Necessary Libraries (if not already available)
    * This must be done on a similar node as the one that will be used, but likely a little beefier since it takes a lot of RAM and hard drive space to compile
    * Launch/Create an Instance (Amazon Linux 2023 AMI using ARM, `t4g.large`, SSH allowed, 10GB EBS storage)
    * Run `wget "https://raw.githubusercontent.com/MoravianUniversity/3DAdapt-AWS-Setup/main/ec2/amazon-linux-compile/all.sh" && bash all.sh`
    * Copy the `*-linux-gnu.tar.gz` files off and store in some accessible location
    * Terminate the machine
  * Gather necessary resources (if not already available)
    * This can be done on any machine (like a local machine)
    * Run `wget "https://raw.githubusercontent.com/MoravianUniversity/3DAdapt-AWS-Setup/main/gather/all.sh" && bash all.sh`
    * Copy the `*.tar.?z` files and store in some accessible location
  * Update the config.py file (in this repo it is ec2/config-template.py with many values filled out for AWS, but there are are several `TODO` that you must fill out).
  * Upload the config.py file to the private S3 bucket
  * Launch/Create Instance
    * Select Amazon Linux 2023 AMI using ARM architecture (takes 1.7 GB, 2.4GB once additional packages are installed)
    * Select `t4g.small` instance type
    * Security group with SSH, HTTP, and HTTPS allowed from anywhere/the internet
    * Create a new EBS volume with at least 5 GB of storage (sometimes it let me create ones this small, other times it insisted on 8 GB)
  * SSH to the EC2 machine and run (update the bucket name first):
    * NOTE: The `setup.sh` has many options for adjusting where it fetches data from and how things are set up, review its source first before running it
    * `wget "https://raw.githubusercontent.com/MoravianUniversity/3DAdapt-AWS-Setup/main/ec2/setup.sh" && bash setup.sh -c s3://<private S3 bucket name>/config.py`
