# quicksight-cur-deployment-tool

### 注意: 

* 此向导中用到的脚本工具是基于 Mac 进行设计的。如果您用的是 Windows 系统，请拷贝至 AWS Amazon Linux 或 AWS Cloud 9 上运行

### **先决条件:**

1.已经配置好 AWS CLI 运行环境（aws-cli/1.18.79 或更新版本）  
&emsp;    https://docs.aws.amazon.com/zh_cn/cli/latest/userguide/cli-chap-configure.html#cli-quick-configuration  
2.确保您的 IAM 用户打开过 QuickSight 控制台进行过用户订阅  
&emsp;    https://docs.aws.amazon.com/zh_cn/quicksight/latest/user/setup-quicksight-for-existing-aws-account.html  
3.升级为 QuickSight 企业版本  
&emsp;    https://docs.aws.amazon.com/zh_cn/quicksight/latest/user/upgrading-subscription.html  
&emsp;    注意: 如果您之前尚未使用过 QuickSight，启用企业版每月会增加 $18 或 $24 的用户订阅成本  
&emsp;    [https://aws.amazon.com/cn/quicksight/pricing/](https://aws.amazon.com/cn/quicksight/pricing/?nc1=h_ls)  
4.已经安装了 “jq” 工具用于解析 json 字符串  

*   在 Amazon linux 或 Cloud 9 上安装 jq  

```
sudo yum -y install jq
```

*   在 Mac 上安装 jq  

```
brew install jq
```




### **部署步骤:**

1.浏览“[设置 Athena 集成](https://docs.aws.amazon.com/zh_cn/cur/latest/userguide/cur-ate-setup.html)” 部分创建 S3 Bucket，启用 CUR 报告(选择 **Parquet** 格式)并用 CloudFormation 模版设置 Athena  

**【可选】**: 如果您想要分析由 AWS 中国区域生产的 CUR 报告，需要把 CUR 报告从中国区的 S3 Bucket 同步到 Global 区域中的 S3 Bucket 中，然后再继续此文档的其它步骤  
a. 在 AWS 中国区域和 Global 区域分别创建两个同名 S3 Bucket  
b. 在中国区域创建 CUR 报告，并保存到准备好的 S3 Bucket 中  
c. 准备一个长期运行的 EC2 实例，配置 Cron job 定期运行如下命令，以便同步中国区域和Global区域的 CUR 数据  

```
aws s3 sync s3://*S3-bucket-name* . --exclude "aws-programmatic-access-test-object" --exclude "*/cost_and_usage_data_status/cost_and_usage_data_status.parquet" —profile *china-iam-profile*
aws s3 sync . s3://*S3-bucket-name* --acl bucket-owner-full-control —profile *global-iam-profile*
```

d. 使用 CloudFormation 模版设置 Athena 集成，然后继续第二步  

注意：  

* 替换 *S3-bucket-name* 为您自己的 S3 Bucket Name，替换 *china-iam-profile *为AWS 中国区域 IAM 用户的 AWS CLI profile， 替换  *global-iam-profile *为AWS Global 区域 IAM 用户的 AWS CLI profile  
* 如果您希望利用无服务器化的方式进行同步，可参考此博客进行配置  
https://aws.amazon.com/cn/blogs/china/lambda-overseas-china-s3-file/  

2.设置存储 CUR Report 的 S3 Bucket 的访问权限，以便 QuickSight 可以正常读取所需数据  
&emsp;    https://docs.aws.amazon.com/zh_cn/quicksight/latest/user/troubleshoot-athena-insufficient-permissions.html  
3.访问 [此站点](https://d12s69h9il8nze.cloudfront.net/)，输入公司名称和 AWS Account ID 进行模版访问授权  
4.打开 [Github](https://github.com/adamhucn/quicksight-cur-deployment-tool) 链接，选择 “Code → Download ZIP ” 下载 quicksight-cur-deployment-tool[](https://github.com/adamhucn/quicksight-cur-deployment-tool)  
5.进入解压后的文件夹，然后运行  “deployQSCUR.sh” 脚本工具  

```
cd quicksight-cur-deployment-tool-master
```
```
bash deployQSCUR.sh
```

6.脚本运行过程中会收集一些配置信息，按需求填写即可  
*注：如您完全按照本博客内容进行配置，且计划把 QuickSight Dashboard 部署在美东一区域，全部保持默认值即可*  
a. Please enter the destination region to deploy this solution(same with Athena/QuickSight) [default:us-east-1]  
b. If you know what SPICE is and want to use SPICE mode, type “spice”. [default:DIRECT_QUERY]  
c. Please input the database name in Athena, which will be used to connect CUR data on S3  
d. Please input the table name within database in previous step, which will be used to connect CUR data on S3  
e. Please input the "Query result location" value from Settings in Athena console [default: s3://aws-athena-query-results-*ACCOUNTID*-*REGION*/].  

7.脚本成功运行后，即可打开 QuickSight Dashboard 进行成本分析  

## **自定义分析视图:**  

如果您想基于现有QuickSight Dashboard 编辑自定义视图，可以在控制台中启用“另存为”功能  

a. 打开 QuickSight Dashboard，单击右上角的“共享”，然后选择“共享控制面板”  
b. 在弹出的窗口中，选择 “管理控制面板访问”  
c. 在 “管理控制面板访问”页面中，对需要授权的账号勾选“另存为”选项  
d. 在“启用另存为”窗口中单击“确认”，关闭 “管理控制面板访问”弹窗后，QuickSight Dashboard 右上角会新增一个“另存为”选项  
e. 单击“另存为” 创建一个新的分析并为其命名  
f.  在新建的 Analysis 中单击“Data set” 图标进行编辑  
g. 在弹出的 “Data sets in this analysis” 页面中选中 Data set 进行编辑  
h. 进入到 Data set 编辑页面后等待所有 CUR 字段加载完成，然后单击 “Save&visualize” 更新 Data set 中的 CUR 字段后，您即可根据自己的需求在 analysis 面板中自定义成本视图了  

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

脚本工具 “deleteAll.sh” 所需的额外权限集为:  
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
