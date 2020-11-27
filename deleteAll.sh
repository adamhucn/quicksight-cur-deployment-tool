### Powered by AWS Enterprise Support 
### Mail: tam-solution-costvisualization@amazon.com
### Version 1.1

checkJQ() {
	# Check if jq is an executable command
    if ! [ -x "$(command -v jq)" ]; then
		echo 'Error: "jq" execution check failed! Please install "jq" tool first.'

		# if jq is not an executable command, show the command to install jq tool
		echo ""
		echo "### Command to install “jq” on Amazon linux or Cloud 9 ###"
		echo "sudo yum -y install jq"
		echo ""
		echo "### Command to install “jq” on Mac ###"
		echo "brew install jq"
		exit 1

    else
    	return
    fi
}

selectRegion() {
	# Get the destination region from console input, default value is the default region in aws config 
	echo -e "Please enter the destination region to deploy this solution(same with Athena/QuickSight) [default:\033[1;36m$CURRENTREGION\033[0m]"
	read -p "Destination Region:" REGIONCUR

	# If consolut input meet the regex, set is as destination region
	if [[ $REGIONCUR =~ ^[a-z]{2,2}-[a-z]{3,9}-[1-9]{1,3}$ ]];then
		return

	# If console input is null, set destination as default region
	elif [ "$REGIONCUR" = "" ];then
		REGIONCUR=$CURRENTREGION	

	# If consolut input doesn't meet the regex, run selectRegion again
	else		
		echo "Invalid region! Please enter correct region name."
		selectRegion
		return
	fi

}

# Check jq installation
checkJQ

# Get the running profile
stsresult=`aws sts get-caller-identity`

# Get the Account ID by running profile
AccountID=`echo $stsresult | jq -r '.Account'`

# Set the default region, only valid in current script session or shell
CURRENTREGION=`aws configure get region`

# If has no default region, set it as us-east-1
if [ "$CURRENTREGION" = "" ]; then
	CURRENTREGION="us-east-1"
fi

# Get the destination region to delete this solution
selectRegion

DATASOURCEID="cur-datasource-id-"$REGIONCUR
DATASETID="cur-dataset-id-"$REGIONCUR
DASHBOARDID="cur-dashboard-id-"$REGIONCUR

# Delete resources created for CUR generated from global and China region
dashboardnum=0
datasetnum=0
datasourcenum=0

DASHBOARDLIST=`aws quicksight list-dashboards --aws-account-id $AccountID --region $REGIONCUR | jq -r '.DashboardSummaryList[].DashboardId'`
DASHBOARDARRAY=($DASHBOARDLIST)

for dashboarditerator in "${DASHBOARDARRAY[@]}";do 
	if [[ $dashboarditerator =~ $DASHBOARDID ]];then 
		aws quicksight delete-dashboard --aws-account-id $AccountID --dashboard-id $dashboarditerator --region $REGIONCUR
		let dashboardnum=$dashboardnum+1
	fi
done

DATASETLIST=`aws quicksight list-data-sets --aws-account-id $AccountID --region $REGIONCUR | jq -r '.DataSetSummaries[].DataSetId'`
DATASETARRAY=($DATASETLIST)

for datasetiterator in "${DATASETARRAY[@]}";do 
	if [[ $datasetiterator =~ $DATASETID ]];then 
		aws quicksight delete-data-set --aws-account-id $AccountID --data-set-id $datasetiterator --region $REGIONCUR
		let datasetnum=$datasetnum+1
	fi
done

DATASOURCELIST=`aws quicksight list-data-sources --aws-account-id $AccountID --region $REGIONCUR | jq -r '.DataSources[].DataSourceId'`
DATASOURCEARRAY=($DATASOURCELIST)

for datasourceiterator in "${DATASOURCEARRAY[@]}";do 
	if [[ $datasourceiterator =~ $DATASOURCEID ]];then 
		aws quicksight delete-data-source --aws-account-id $AccountID --data-source-id $datasourceiterator --region $REGIONCUR
		let datasourcenum=$datasourcenum+1
	fi
done

echo ""
echo Deletion Summary:
echo $dashboardnum dashboard\(s\) deleted.
echo $datasetnum dataset\(s\) deleted.
echo $datasourcenum datasource\(s\) deleted.
