# quicksight-cur-deployment-tool

### Note: 

* This guide is designed on Mac client. If you are using a Windows PC. Consider to run this on Amazon Linux or Cloud 9.

### **Prerequisites:**

1.AWS CLI environment configured (at least aws-cli/1.18.79)  
&emsp;    https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html#cli-quick-configuration  
2.Set up Amazon QuickSight for an existing AWS user  
&emsp;    https://docs.aws.amazon.com/quicksight/latest/user/setup-quicksight-for-existing-aws-account.html  
3.Enable Enterprise Edition for QuickSight (navigate to QuickSight Admin to purchase Enterprise license).  
&emsp;    https://docs.aws.amazon.com/quicksight/latest/user/upgrading-subscription.html  
&emsp;    Note: If you do not use QuickSight before, this will add $18 or $24 subscription fee into your monthly bill  
&emsp;    [https://aws.amazon.com/quicksight/pricing/](https://aws.amazon.com/quicksight/pricing/?nc1=h_ls)  
4.“jq” tool installed on your client  

*   Command to install jq on Amazon linux  

```
sudo yum -y install jq
```

*   Command to install jq on Mac  

```
brew install jq
```




### **Steps:**

1.Go through“[Setting up Amazon Athena integration](https://docs.aws.amazon.com/cur/latest/userguide/cur-ate-setup.html)” to create S3 bucket/CUR(choose **Parquet** format) and set up Athena integration by CloudFormation.  

**[Optional]**: If you want to analyze CUR created from China region, you need to sync CUR data between China and global region  
a. Create two S3 buckets in China region and global region separately, use the same bucket name  
b. Enable CUR and save to S3 bucket in China region  
c. Run following command periodically, so that new data will be continuously synchronized to S3 bucket in global region  

```
aws s3 sync s3://*S3-bucket-name* . --exclude "aws-programmatic-access-test-object" --exclude "*/cost_and_usage_data_status/cost_and_usage_data_status.parquet" —profile *china-iam-profile*
aws s3 sync . s3://*S3-bucket-name* --acl bucket-owner-full-control —profile *global-iam-profile*
```

d. Set up Athena integration by CloudFormation, then go on with step 2  

Note：  

* Change *S3-bucket-name* to your S3 Bucket Name，change *china-iam-profile * to your IAM user profile in China region， change  *global-iam-profile * to your IAM user profile in global region
* If you want to synchorize CUR by a serverless architecture, please reference this blog  
https://aws.amazon.com/cn/blogs/china/lambda-overseas-china-s3-file/  

2.Grant permissions on S3 bucket, so that QuickSight can access CUR files stored in it
&emsp;    https://docs.aws.amazon.com/zh_cn/quicksight/latest/user/troubleshoot-athena-insufficient-permissions.html  
3.Visit [this site](https://d12s69h9il8nze.cloudfront.net/)，enter company name and AWS Account ID to authorize permissions for QuickSight template  
4.Open [Github](https://github.com/adamhucn/quicksight-cur-deployment-tool) ，click “Code → Download ZIP ” to download quicksight-cur-deployment-tool[](https://github.com/adamhucn/quicksight-cur-deployment-tool)  
5.Navigate to extracted folder and run “deployQSCUR.sh”  

```
cd quicksight-cur-deployment-tool-master
```
```
bash deployQSCUR.sh
```

6.Type answers for following questions prompted by this script
*Note：If all steps according to the content of this guide，and plan to deploy QuickSight Dashboard in us-east-1，keep all the defauls is ok*  
a. Please enter the destination region to deploy this solution(same with Athena/QuickSight) [default:us-east-1]  
b. Please input the database name in Athena, which will be used to connect CUR data on S3  
c. Please input the table name within database in previous step, which will be used to connect CUR data on S3  
d. Please input the "Query result location" value from Settings in Athena console [default: s3://aws-athena-query-results-*ACCOUNTID*-*REGION*/].  

7.Open your QuickSight dashboard to analyze cost  

## **Customize your analysis:**  

If you want to have a customized view based on existing QuickSight dashboard, you can enable the "Save As" function in the console  

a. Open the dashboard, then click "share" button from upper right corner  
b. In the pop up window click “Manage Dashboard access”  
c. On “Manage Dashboard access” page，tick "Save as" for your account  
d. Click "Confirm" on “Enable save as” window, close “Manage Dashboard access”，then you will see a new "Save as" button appear on the upper right corner  
e. Click "Save as" to create an analysis from this dashboard. Now you can customize any visual on new analysis.  

### Main cost of this solution:  

1.QuickSight Enterprise Edition, $18 or $24 per month based on your subscription  
&emsp;    https://aws.amazon.com/quicksight/pricing/  
2.Athena query cost
&emsp;    Take us-east-1 as example，$5.00 per TB of data scanned  
&emsp;    https://aws.amazon.com/athena/pricing/  
3.S3 S3 standard storage cost   
&emsp;    Take us-east-1 as example  
&emsp;    $0.023 per GB for storage  
&emsp;    $0.0004 per 1,000 GET requests on CUR file  
&emsp;    https://aws.amazon.com/s3/pricing/  
4.A recurring(2-3 times a day) Glue crawler that keeps your CUR table in Athena up-to-date  
&emsp;    Take us-east-1 as example, $0.44 per DPU-Hour, billed per second, with a 10-minute minimum per crawler run  
&emsp;    https://aws.amazon.com/glue/pricing/  
5.A recurring(2-3 times a day) Lambda to trigger Athena table update  
&emsp;    Take us-east-1 as example，128MB, $0.000002083 per second  
&emsp;    https://aws.amazon.com/lambda/pricing/  
6.If you run this script tool on EC2 or Cloud 9, will have additional cost based on you instance type  
&emsp;    https://aws.amazon.com/ec2/pricing/on-demand/  
&emsp;    https://aws.amazon.com/cloud9/pricing/  

### **Minimal permissions :**  

The minimal permissions for “deployQSCUR.sh” are:  
{  
&emsp;"Version": "2012-10-17",  
&emsp;"Statement": [  
&emsp;&emsp;{  
&emsp;&emsp;&emsp;"Sid": "deployQSCURPolicy",  
&emsp;&emsp;&emsp;"Effect": "Allow",  
&emsp;&emsp;&emsp; "Action": [  
&emsp;&emsp;&emsp;&emsp;"EC2:DescribeRegions",  
&emsp;&emsp;&emsp;&emsp;"s3:GetBucketLocation",  
&emsp;&emsp;&emsp;&emsp;"s3:ListBucket",  
&emsp;&emsp;&emsp;&emsp;"s3:PutObject",  
&emsp;&emsp;&emsp;&emsp;"s3:GetObject",  
&emsp;&emsp;&emsp;&emsp;"glue:GetPartitions",  
&emsp;&emsp;&emsp;&emsp;"glue:GetDatabase",  
&emsp;&emsp;&emsp;&emsp;"glue:GetDatabases",  
&emsp;&emsp;&emsp;&emsp;"glue:GetTable",  
&emsp;&emsp;&emsp;&emsp;"glue:GetTables",  
&emsp;&emsp;&emsp;&emsp;"athena:ListDatabases",  
&emsp;&emsp;&emsp;&emsp;"athena:GetDatabase",  
&emsp;&emsp;&emsp;&emsp;"athena:ListTableMetadata",  
&emsp;&emsp;&emsp;&emsp;"athena:GetTableMetadata",  
&emsp;&emsp;&emsp;&emsp;"athena:StartQueryExecution",  
&emsp;&emsp;&emsp;&emsp;"athena:GetQueryExecution",  
&emsp;&emsp;&emsp;&emsp;"athena:GetQueryResults",  
&emsp;&emsp;&emsp;&emsp;"quicksight:ListUsers",  
&emsp;&emsp;&emsp;&emsp;"quicksight:CreateUser",  
&emsp;&emsp;&emsp;&emsp;"quicksight:CreateAdmin",  
&emsp;&emsp;&emsp;&emsp;"quicksight:DescribeDataSource",  
&emsp;&emsp;&emsp;&emsp;"quicksight:UpdateDataSourcePermissions",  
&emsp;&emsp;&emsp;&emsp;"quicksight:UpdateDataSetPermissions",  
&emsp;&emsp;&emsp;&emsp;"quicksight:PassDataSource",  
&emsp;&emsp;&emsp;&emsp;"quicksight:CreateDataSet",  
&emsp;&emsp;&emsp;&emsp;"quicksight:DescribeDataSet",  
&emsp;&emsp;&emsp;&emsp;"quicksight:PassDataSet"  
&emsp;&emsp;&emsp;&emsp;"quicksight:DescribeTemplate",  
&emsp;&emsp;&emsp;&emsp;"quicksight:CreateDataSource",  
&emsp;&emsp;&emsp;&emsp;"quicksight:CreateDashboard",  
&emsp;&emsp;&emsp;&emsp;"quicksight:DescribeDashboard",  
&emsp;&emsp;&emsp;&emsp;"quicksight:UpdateDashboardPermissions"  
&emsp;&emsp;&emsp;],  
&emsp;&emsp;&emsp;"Resource": "*"  
&emsp;&emsp;}  
&emsp;]  
}  

More permissions necessary for “deleteAll.sh” are:  
{  
&emsp; "Version": "2012-10-17",  
&emsp; "Statement": [  
&emsp;&emsp; {  
&emsp;&emsp;&emsp; "Sid": "deleteAllPolicy",  
&emsp;&emsp;&emsp; "Effect": "Allow",  
&emsp;&emsp;&emsp; "Action": [  
&emsp;&emsp;&emsp;&emsp;"quicksight:DeleteDataSource",  
&emsp;&emsp;&emsp;&emsp;"quicksight:DeleteDataSet",  
&emsp;&emsp;&emsp;&emsp;"quicksight:DeleteDashboard"  
&emsp;&emsp;&emsp; ],  
&emsp;&emsp;&emsp; "Resource": "*"  
&emsp;&emsp; }  
&emsp; ]  
}  
