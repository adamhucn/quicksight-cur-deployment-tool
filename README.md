# quicksight-cur-deployment-tool

### 注意: 

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
&emsp;https://docs.aws.amazon.com/cur/latest/userguide/cur-ate-setup.html  

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

## **自定义分析视图:**  

如果您想基于现有QuickSight Dashboard 编辑自定义视图，可以在控制台中启用“另存为”功能  

a. 打开 QuickSight Dashboard，单击右上角的“共享”，然后选择“共享控制面板”  
b. 在弹出的窗口中，选择 “管理控制面板访问”  
c. 在 “管理控制面板访问”页面中，对需要授权的账号勾选“另存为”选项，然后  
d. 在“启用另存为”窗口中单击“确认”，关闭 “管理控制面板访问”弹窗后，即可在 Dashboard 右上角看到新增的“另存为”选项  
e. 单击“另存为” 创建一个新的分析后，您即可根据自己的需求在分析面板中进行自定义了  

### 本方案涉及的主要成本:  

1.QuickSight 企业版订阅费，根据订阅方式不同，每月 $18 或 $24 美元  
&emsp;    https://aws.amazon.com/cn/quicksight/pricing/  
2.Athena 数据查询费用  
&emsp;    以美东一区域为例，每扫描 1TB 数据 $5.00 美元  
&emsp;    https://aws.amazon.com/cn/athena/pricing/  
3.S3 数据存储费用  
&emsp;    以美东一区域为例  
&emsp;    每 1GB 数据存储1个月成本为 $0.023 美元  
&emsp;    每 1,000 个 GET 请求 $0.0004 美元  
&emsp;    https://aws.amazon.com/cn/s3/pricing/  
4.每天运行 2-3 次的 Glue Crawler，可以使您在 Athena 中的 CUR Table 保持最新状态  
&emsp;    以美东一区域为例，每 DPU-Hour $0.44 美元，按秒计费，每运行一次最小计费单元为10分钟  
&emsp;    https://aws.amazon.com/cn/glue/pricing/  
5.每天运行 2-3 次的 Lambda 程序，用来触发 Glue Crawler  
&emsp;    以美东一区域为例，配置为 128MB 内存, 每秒 $0.000002083 美元  
&emsp;    https://aws.amazon.com/cn/lambda/pricing/  
6.如果您在 EC2 或 Cloud 9 上运行此脚本工具，将会按照实例类型单独收取相关费用  
&emsp;    https://aws.amazon.com/cn/ec2/pricing/on-demand/  
&emsp;    https://aws.amazon.com/cn/cloud9/pricing/  

### **所需最小权限 :**  

脚本工具 “deployQSCUR.sh” 所需的最小权限集为:  
{  
&emsp;"Version": "2020-08-04",  
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

脚本工具 “deleteAll.sh” 所需的额外权限集为:  
{  
&emsp; "Version": "2020-08-04",  
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
