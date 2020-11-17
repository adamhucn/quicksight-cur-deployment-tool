### Powered by AWS Enterprise Support 
### Mail: tam-solution-costvisualization@amazon.com
### Version 1.2

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

getCURDataSourceRegion() {
	# Construct the Athena query string to get one region value from CUR database
	QUERYSTRING="SELECT product_region FROM "\"$ATHENADB\".\"$ATHENATABLE\"" where length(product_region)>6 limit 1"

	# Get the Athena execution ID by running Athena query
	EXECUTIONID=`aws athena start-query-execution \
	--query-string "$QUERYSTRING" \
	--result-configuration "OutputLocation"="$OUTPUTBUCKET" | jq -r '.QueryExecutionId'`

	# Validate the query result every 2 seconds
	for curdatasourcetimer in {1..15}
	do
		EXECUTIONSTATUS=`aws athena get-query-execution --query-execution-id $EXECUTIONID | jq -r '.QueryExecution.Status.State'`
		
		# If qeury succeed, jump out the for loop, then check CUR data source region from query result
		if [[ $EXECUTIONSTATUS == "SUCCEEDED" ]]; then
			break

		elif [[ $EXECUTIONSTATUS == "RUNNING" ]]; then

			if [[ $curdatasourcetimer == 15 ]]; then
				echo Get CUR data source region timeout, please check your network connectivity and try again.
				exit
			fi

			echo Getting CUR data source region...

		# If query failed, exit this script
		else
			echo ""
			echo "Get CUR data source region failed! Please check your Athena configuration and IAM permissions."
			exit
		fi

		sleep 2s
	done

	# Get the region name from query result
	ATHENAQUERYRESULTS=`aws athena get-query-results --query-execution-id $EXECUTIONID | jq -r '.ResultSet.Rows[1].Data[0].VarCharValue'`

	# Get all region list and put it in an Array
	GLOBALREGIONLIST=($(aws ec2 describe-regions --query "Regions[].{Name:RegionName}" --output text))

	# Initialize the variable CURDATASOURCEREGION
	CURDATASOURCEREGION=""

	# Compare the region result with available regions to get region values
	for compareregion in "${GLOBALREGIONLIST[@]}";do 
		# Check if this region is in global region list
		if [ $compareregion = $ATHENAQUERYRESULTS ];then 

			# Get CURDATASOURCEREGIONSTRING value to define the name for datasource/dataset/dashboard
			CURDATASOURCEREGIONSTRING=""
			# Set a Region marker for global region
			CURDATASOURCEREGION="global"
			break

		# Check if this region is in China region list
		elif [ "$ATHENAQUERYRESULTS" = "cn-north-1" -o "$ATHENAQUERYRESULTS" = "cn-northwest-1" ];then 
			# Get CURDATASOURCEREGIONSTRING value to define the name for datasource/dataset/dashboard
			CURDATASOURCEREGIONSTRING="cn-"
			# Set a Region marker for Chinia region
			CURDATASOURCEREGION="China"
			break
		fi
	done

	# Get the lengh of region result
	CURDATASOURCEREGIONLENGTH=${#CURDATASOURCEREGION}
	
	# If region length lower than 1, need to update this tool
	if [ "$CURDATASOURCEREGIONLENGTH" -lt 1 ]; then
		echo "UNKNOWN region! Please try to run this script again or contact GCR Enterprise Support Cost Virsualization team to fix it."
		exit
	fi

	echo CUR created from $CURDATASOURCEREGION region.
}

getCURDateFormat(){
	# Construct the Athena query string to get the date format
	# Note: cannot add quote for ATHENADB and ATHENATABLE in describe command
	QUERYSTRING="describe "$ATHENADB.$ATHENATABLE" bill_billing_period_start_date;"

	# Get the Athena execution ID by running Athena query
	EXECUTIONID=`aws athena start-query-execution \
	--query-string "$QUERYSTRING" \
	--result-configuration "OutputLocation"="$OUTPUTBUCKET" | jq -r '.QueryExecutionId'`

	# Validate the query result every 2 seconds
	for curdateformattimer in {1..15}
	do
		EXECUTIONSTATUS=`aws athena get-query-execution --query-execution-id $EXECUTIONID | jq -r '.QueryExecution.Status.State'`
		
		# If qeury succeed, jump out the for loop, then check Date format from query result
		if [[ $EXECUTIONSTATUS == "SUCCEEDED" ]]; then
			break

		elif [[ $EXECUTIONSTATUS == "RUNNING" ]]; then
			if [[ $curdateformattimer == 15 ]]; then
				echo Get CUR date format timeout, please check your network connectivity and try again.
				exit
			fi

			echo Getting CUR date format...

		# If qeury failed, exit this script
		else
			echo ""
			echo "Get CUR date format failed! Please check your Athena configurations and IAM permissions."

			exit
		fi

		sleep 2s
	done

	# Get the Date format from query result
	ATHENAQUERYRESULTS=`aws athena get-query-results --query-execution-id $EXECUTIONID | jq -r '.ResultSet.Rows[0].Data[0].VarCharValue' | awk '{print $2}'`
	echo Date format in CUR file is $ATHENAQUERYRESULTS.

	# Define the Date format string for physical configuration file
	if [ "$ATHENAQUERYRESULTS" = "bigint" ]; then
		DATEFORMAT="INTEGER"
	elif [ "$ATHENAQUERYRESULTS" = "timestamp" ]; then
		DATEFORMAT="DATETIME"
	else
		DATEFORMAT="STRING"
	fi
}

isEMR() {
	# Construct the Athena query string to check existence of column resource_tags_aws_elasticmapreduce_job_flow_id
	EMRTAGQUERYSTRING="SELECT resource_tags_aws_elasticmapreduce_job_flow_id FROM "\"$ATHENADB\".\"$ATHENATABLE\"" limit 1"

	# Get the Athena execution ID by running Athena query
	EMRTAGEXECUTIONID=`aws athena start-query-execution \
	--query-string "$EMRTAGQUERYSTRING" \
	--result-configuration "OutputLocation"="$OUTPUTBUCKET" | jq -r '.QueryExecutionId'`

	# Validate the query result every 2 seconds
	for emrtimer in {1..15}
	do
		EMRTAGEXECUTIONSTATUS=`aws athena get-query-execution --query-execution-id $EMRTAGEXECUTIONID | jq -r '.QueryExecution.Status.State'`
		
		# If qeury succeed, set the flag to has-emr-tag
		if [[ $EMRTAGEXECUTIONSTATUS == "SUCCEEDED" ]]; then
			EMR="has-emr-tag"
			break

		elif [[ $EMRTAGEXECUTIONSTATUS == "RUNNING" ]]; then
			if [[ $emrtimer == 15 ]]; then
				echo Checking EMR tag timeout, please check your network connectivity and try again.
				exit
			fi

		# If qeury failed, set the flag to no-emr-tag
		else			
			EMR="no-emr-tag"
			echo -e EMR cost allocation tag has not been enabled, visuals in EMR sheet will show "\033[33m \"No Data\" \033[0m".
			break
		fi

		sleep 2s
	done
}

isSP() {
	# Construct the Athena query string to check existence of column savings_plan_savings_plan_a_r_n
	SPQUERYSTRING="SELECT savings_plan_savings_plan_a_r_n FROM "\"$ATHENADB\".\"$ATHENATABLE\"" limit 1"

	# Get the Athena execution ID by running Athena query
	SPEXECUTIONID=`aws athena start-query-execution \
	--query-string "$SPQUERYSTRING" \
	--result-configuration "OutputLocation"="$OUTPUTBUCKET" | jq -r '.QueryExecutionId'`

	# Validate the query result every 2 seconds
	for sptimer in {1..15}
	do
		SPEXECUTIONSTATUS=`aws athena get-query-execution --query-execution-id $SPEXECUTIONID | jq -r '.QueryExecution.Status.State'`
		
		# If qeury succeed, set the flag to has-sp-column
		if [[ $SPEXECUTIONSTATUS == "SUCCEEDED" ]]; then
			SP="has-sp-column"
			break

		elif [[ $SPEXECUTIONSTATUS == "RUNNING" ]]; then
			if [[ $sptimer == 15 ]]; then
				echo Checking SP columns timeout, please check your network connectivity and try again.
				exit
			fi

		# If qeury failed, set the flag to no-sp-column
		else	
			SP="no-sp-column"			
			break
		fi

		sleep 2s
	done
}

isEDP() {
	# Construct the Athena query string to check existence of column "line_item_net_unblended_cost", _net_ represent it's a EDP column
	EDPQUERYSTRING="SELECT line_item_net_unblended_cost FROM "\"$ATHENADB\".\"$ATHENATABLE\"" limit 1"

	# Get the Athena execution ID by running Athena query
	EDPEXECUTIONID=`aws athena start-query-execution \
	--query-string "$EDPQUERYSTRING" \
	--result-configuration "OutputLocation"="$OUTPUTBUCKET" | jq -r '.QueryExecutionId'`

	# Validate the query result every 2 seconds
	for edptimer in {1..15}
	do
		EDPEXECUTIONSTATUS=`aws athena get-query-execution --query-execution-id $EDPEXECUTIONID | jq -r '.QueryExecution.Status.State'`
		
		# If qeury succeed, set the flag to has-edp
		if [[ $EDPEXECUTIONSTATUS == "SUCCEEDED" ]]; then
			EDP="has-edp-column"
			break

		elif [[ $EDPEXECUTIONSTATUS == "RUNNING" ]]; then

			if [[ $edptimer == 15 ]]; then
				echo Checking EDP timeout, please check your network connectivity and try again.
				exit
			fi

			echo Checking EDP item from CUR table...

		# If qeury failed, set the flag to no-edp-column
		else
			EDP="no-edp-column"

			break
		fi

		sleep 2s
	done
}

# Because of template update, no need tag in visual, deprecated this function in v 0.7
isTAG() {
	# Check if TAG enabled on this customer account
	read -p "Has this account enabled a specific project/program based Tag? If yes, please input \"tag name\"(Only support one tag currently). If no, press Enter. [Default:N]:" TAG

	if [ "$TAG" = "N" -o "$TAG" = "n" -o "$TAG" = "" ];then
		Cal_Project="''"
				
	elif [ "$TAG" = "Y" -o "$TAG" = "y" ];then
		echo "Please enter the correct TAG value, not \"Y\" or \"y\" !"

		isTAG
	else

		TAGQUERYSTRING="SELECT resource_tags_user_"$TAG" FROM "$ATHENADB.$ATHENATABLE" limit 1"

		TAGEXECUTIONID=`aws athena start-query-execution \
		--query-string "$TAGQUERYSTRING" \
		--result-configuration "OutputLocation"="$OUTPUTBUCKET" | jq -r '.QueryExecutionId'`

		for tagtimer in {1..15}
		do
			TAGEXECUTIONSTATUS=`aws athena get-query-execution --query-execution-id $TAGEXECUTIONID | jq -r '.QueryExecution.Status.State'`
			
			if [[ $TAGEXECUTIONSTATUS == "SUCCEEDED" ]]; then
				echo ""
				echo Valid TAG! Continue ...
				break

			elif [[ $TAGEXECUTIONSTATUS == "RUNNING" ]]; then

				if [[ $tagtimer == 15 ]]; then
					echo Tag validation timeout, please check your network connectivity and try again.
					exit
				fi

				echo Checking TAG from CUR table ...

			else
				echo ""
				echo Can not find TAG \"$TAG\" from your CUR table, please enter the TAG value again ...

				# If there is other actions after if block, must return after run funtion again,or will run remnant actions multi times
				isTAG
				return
			fi

			sleep 2s
		done

		Cal_Project="{resource_tags_user_"$TAG"}"
	
	fi
}

updateConfigurationFile() {
	### Note: Column name in physical configuration file cannot be same with calculated column defined in logical configuration file
	
	### Update EMR tag part
	# If EMR cost allocation disabled, delete resource_tags_aws_elasticmapreduce_job_flow_id part in physical config file
	if [[ $EMR == "no-emr-tag" ]];then
		cat physical-table-map.json | jq 'del(.string.RelationalTable.InputColumns[] | select(.Name == "resource_tags_aws_elasticmapreduce_job_flow_id"))' >> tmpjson && mv tmpjson physical-table-map.json
	# If EMR cost allocation enabled, delete resource_tags_aws_elasticmapreduce_job_flow_id part in logical config file
	else
		cat logical-table-map.json | jq 'del(.string.DataTransforms[] | select(.CreateColumnsOperation.Columns[0].ColumnName == "resource_tags_aws_elasticmapreduce_job_flow_id"))' >> tmpjson && mv tmpjson logical-table-map.json
	fi

	### Update Saving Plan comumn part
	# If do not contain SP items, delete SP columns in physical config file
	if [[ $SP == "no-sp-column" ]];then
		cat physical-table-map.json | jq 'del(.string.RelationalTable.InputColumns[] | select(.Name == "savings_plan_region"))' >> tmpjson && mv tmpjson physical-table-map.json
		cat physical-table-map.json | jq 'del(.string.RelationalTable.InputColumns[] | select(.Name == "savings_plan_net_savings_plan_effective_cost"))' >> tmpjson && mv tmpjson physical-table-map.json
	
	# If contain SP items, delete SP columns in logical config file
	else
		cat logical-table-map.json | jq 'del(.string.DataTransforms[] | select(.CreateColumnsOperation.Columns[0].ColumnName == "savings_plan_net_savings_plan_effective_cost"))' >> tmpjson && mv tmpjson logical-table-map.json

	fi

	### update Athena configurations and EDP/SP related columns
	### Note: update this at last, in case column name changed before deletion in previous steps
	# If client is Mac OS
	if [[ $UNAME == "Darwin" ]];then	
		# update Athena configurations
		sed -i "" "s#DATEFORMATHOLDER#$DATEFORMAT#" physical-table-map.json
		sed -i "" "s#ATHENADBHOLDER#$ATHENADB#" physical-table-map.json
		sed -i "" "s#ATHENATABLEHOLDER#$ATHENATABLE#" physical-table-map.json

		# If do not contain EDP items, remove the string "_net_" for columns
		if [[ $EDP == "no-edp-column" ]];then
			sed -i "" "s/_net_/_/g" logical-table-map.json
			sed -i "" "s/_net_/_/g" physical-table-map.json
		fi

		# If signed EDP, remove SP related keywords in calculated fields 
		if [[ $SP == "no-sp-column" ]]; then
			sed -i "" "s#+{savings_plan_net_savings_plan_effective_cost}##" logical-table-map.json
			sed -i "" "s#+{savings_plan_savings_plan_effective_cost}##" logical-table-map.json
		fi
	
	# If client is other linux, using different sed syntax
	else
		sed -i "s#DATEFORMATHOLDER#$DATEFORMAT#" physical-table-map.json
		sed -i "s#ATHENADBHOLDER#$ATHENADB#" physical-table-map.json
		sed -i "s#ATHENATABLEHOLDER#$ATHENATABLE#" physical-table-map.json

		if [[ $EDP == "no-edp-column" ]];then
			sed -i "s/_net_/_/g" logical-table-map.json
			sed -i "s/_net_/_/g" physical-table-map.json
		fi

		if [[ $SP == "no-sp-column" ]]; then
			sed -i "s#+{savings_plan_net_savings_plan_effective_cost}##" logical-table-map.json
			sed -i "s#+{savings_plan_savings_plan_effective_cost}##" logical-table-map.json
		fi
	fi
}

# Do not include this in main funtion currently, reserve this for future use
getTemplate() {
	# Update new template arn in necessary
	read -p "Input New/Updated QuickSight template ARN here. If you do not have it,keep default:" QSTEMARN

	# Set the default template arn
	if [ "$QSTEMARN" = "" ];then
		QSTEMARN="arn:aws:quicksight:us-east-1:673437017715:template/CUR-MasterTemplate-Pub"
		
	else		
		return
	fi
}

# Get required Athena configurations
getAthenaConfiguration() {
	# Get Athena Database name for CUR
	getAthenaDatabase

	# Get Athena Table name for CUR
	getAthenaTable

	# Get Athena query result location to ensure successful Athena query
	getAthenaBucket
}

getAthenaDatabase() {
	# List all Athena databases in AwsDataCatalog and assign it to an Array
	ATHENADBLIST=`aws athena list-databases --catalog-name AwsDataCatalog | jq -r .DatabaseList[].Name`
	ATHENADBARRAY=($ATHENADBLIST)

	# Print the database list, so that we can find the correct one for CUR easily
	echo ""
	echo "All available Athena dababases in your environemnt are:"
	echo "******************************************************"
	# Add quote "" to wrap the text for every database name
	echo "$ATHENADBLIST"
	echo "******************************************************"

	# If Athena database is created from official cloudformation tempalte, the database name will contain this default string. In this situation, we will help you to select the default database automatically
	defaultdbstring="athenacurcfn_"

	# Initialize the defaul db name as null
	ATHENADEFAULTDB=""

	# If there is one database name contain defaultdbstring, set the default database as this database
	for defaultdb in "${ATHENADBARRAY[@]}";do 
		if [[ $defaultdb =~ $defaultdbstring ]];then 
			ATHENADEFAULTDB=$defaultdb
			break
		fi
	done

	### Get database value from console input
	# If matched one default dabatase, show the default database name in prompted question
	if [ "$ATHENADEFAULTDB" != "" ];then
		echo -e "Please input the database name in Athena, which will be used to connect CUR data on S3 [default:\033[1;36m$ATHENADEFAULTDB\033[0m]" 
		read -p "Athena Database:" ATHENADB
	
	# If failed to get the default database, get database name from console input 
	else
		echo -e "Please input the database name in Athena, which will be used to connect CUR data on S3:" 
		read -p "Athena Database:" ATHENADB
	fi

	# If failed to get the default database, and console input is null, run getAthenaDatabase again
	if [ "$ATHENADB" = "" -a "$ATHENADEFAULTDB" = "" ];then
		echo ""
		echo Please enter a valid Athena database name here ...

		getAthenaDatabase
		return

	# If matched one default dabatase, and console input is null, set Athena database name as default database name
	elif [[ "$ATHENADB" = "" ]];then
		ATHENADB=$ATHENADEFAULTDB
	fi
	
	### Run an Athena query to validate the database value
	# Run a CLI command to get the database name
	ATHENADBRESULT=`aws athena get-database --catalog-name AWSDataCatalog --database-name $ATHENADB | jq -r '.Database.Name'`

	# If returned database is smae with current one, validation successfully
	if [[ $ATHENADBRESULT == $ATHENADB ]];then
		:

	# If validation failed, run getAthenaDatabase again to get database value from console input
	else 
		echo ""
		echo Database validation failed, please enter Athena database name again ...
		getAthenaDatabase
		return
	fi
}

getAthenaTable() {
	# List all tables from database we got in getAthenaDatabase
	ATHENATABLELIST=`aws athena list-table-metadata --catalog-name AwsDataCatalog --database-name $ATHENADB | jq -r .TableMetadataList[].Name`

	# Print the table list, so that we can find the correct one for CUR easily
	echo ""
	echo "All available tables in database \"$ATHENADB\" are:"
	echo "******************************************************"
	echo "$ATHENATABLELIST"
	echo "******************************************************"

	# If Athena database is created from official cloudformation tempalte, the database name will contain defaultdbstring, and the rest of database name will be the table name. In this situation, set Athena default table name to this value
	if [[ "$ATHENADB" =~ "$defaultdbstring" ]]; then
		ATHENADEFAULTTABLE=${ATHENADB#*athenacurcfn_}
	# If Athena database name do not contain defaultdbstring, we cannot predict default table name, set it to null
	else
		ATHENADEFAULTTABLE=""
	fi

	# If got the default table name, show the default tale name in prompted question
	if [[ "$ATHENADEFAULTTABLE" != "" ]]; then
		echo -e "Please input the table name within database "\"$ATHENADB\"", which will be used to connect CUR data on S3 [default:\033[1;36m$ATHENADEFAULTTABLE\033[0m]" 
		read -p "Athena Table:" ATHENATABLE

	# If failed to get the default table, get table name from console input 
	else
		echo -e "Please input the table name within database "\"$ATHENADB\"", which will be used to connect CUR data on S3:" 
		read -p "Athena Table:" ATHENATABLE
	fi
	
	# If failed to get the default table, and console input is null, run getAthenaTable again
	if [ "$ATHENATABLE" = "" -a "$ATHENADEFAULTTABLE" = "" ];then
		echo ""
		echo Please enter a valid Athena table name here ...

		getAthenaTable
		return

	# If got the default table, and console input is null, set Athena table name as default table name	
	elif [[ "$ATHENATABLE" = "" ]];then
		ATHENATABLE=$ATHENADEFAULTTABLE
	fi

	### Run an Athena query to validate the table value
	# Run a CLI command to get the table name
	ATHENATABLERESULT=`aws athena get-table-metadata --catalog-name AWSDataCatalog --database-name $ATHENADB --table-name $ATHENATABLE | jq -r '.TableMetadata.Name'`

	# If returned table is smae with current one, validation successfully
	if [[ $ATHENATABLERESULT == $ATHENATABLE ]];then
		:

	# If validation failed, run getAthenaTable again to get table value from console input
	else
		echo ""
		echo Table validation failed, please enter Athena table name again ...

		getAthenaTable
		return
	fi
}

getAthenaBucket() {
	# Get Athena query result location from console input, default is s3://aws-athena-query-results-$AccountID-$REGIONCUR/
	echo ""
	echo -e "Please input the \"Query result location\" value from Settings in Athena console [default:\033[1;36ms3://aws-athena-query-results-$AccountID-$REGIONCUR/\033[0m]" 
	read -p "Query result location:" OUTPUTBUCKET
	echo ""

	# If OUTPUTBUCKET meet the regex, we will run a Athena query to test it
	if [[ $OUTPUTBUCKET =~ ^s3:\/\/.+\/$ ]];then
		echo "Begin to run test query ..."

	# If console input is null, set OUTPUTBUCKET as default value
	elif [ "$OUTPUTBUCKET" = "" ];then
		OUTPUTBUCKET="s3://aws-athena-query-results-"$AccountID"-"$REGIONCUR"/"

	# If OUTPUTBUCKET doesn't meet the regex, run getAthenaBucket again
	else		
		echo "Invalid Bucket format, please enter correct Bucket value [Example: s3://query-results-bucket/folder/]"

		getAthenaBucket
		return
	fi

	# Construct the Athena query string to run a test query
	QUERYSTRING="SELECT * FROM "\"$ATHENADB\".\"$ATHENATABLE\"" limit 1"

	# Get the execution ID after test query
	EXECUTIONID=`aws athena start-query-execution \
	--query-string "$QUERYSTRING" \
	--result-configuration "OutputLocation"="$OUTPUTBUCKET" | jq -r '.QueryExecutionId'`

	# Validate the query result every 2 seconds
	for athenabuckettimer in {1..15}
	do
		EXECUTIONSTATUS=`aws athena get-query-execution --query-execution-id $EXECUTIONID | jq -r '.QueryExecution.Status.State'`

		if [[ $EXECUTIONSTATUS == "SUCCEEDED" ]]; then
			echo All Athena configurations are valid.
			break

		elif [[ $EXECUTIONSTATUS == "RUNNING" ]]; then
			if [[ $athenabuckettimer == 15 ]]; then
				echo Running test query timeout, please check your network connectivity and try again.
				exit
			fi
			echo Running test query on Athena...

		else
			echo ""
			echo Cannot run Athena query successfully, please check your Bucket value and enter again!
			echo ""

			getAthenaBucket
			return
		fi

		sleep 2s
	done
}

selectRegion() {
	# Get the destination region from console input, default value is the default region in aws config 
	echo -e "Please enter the destination region to deploy this solution(same with Athena/QuickSight) [default:\033[1;36m$CURRENTREGION\033[0m]"
	read -p "Destination Region:" REGIONCUR

	# If console input meet the regex, set is as destination region
	if [[ $REGIONCUR =~ ^[a-z]{2,2}-[a-z]{3,9}-[1-9]{1,3}$ ]];then
		return

	# If console input is null, set destination as default region
	elif [ "$REGIONCUR" = "" ];then
		REGIONCUR=$CURRENTREGION	

	# If console input doesn't meet the regex, run selectRegion again
	else		
		echo "Invalid region! Please enter correct region name."
		selectRegion
		return
	fi

}

chooseQueryMode() {

	# Set the default query mode as DIRECT_QUERY
	QUERYMODE="DIRECT_QUERY"

	# Choose the query mode
	echo -e "If you know what SPICE is and want to use SPICE mode, type \"spice\". [default:\033[1;36m$QUERYMODE\033[0m]"
	read -p "Query Mode:" QUERYMODESTRING

	# If user choose SPICE, change the value of QUERYMODE
	if [ "$QUERYMODESTRING" = "spice" -o "$QUERYMODESTRING" = "SPICE" ];then
		QUERYMODE="SPICE"

	# If console input is null, keep query mode as default 
	elif [ "$QUERYMODESTRING" = "" ];then
		:

	# If console input is not valid, run chooseQueryMode again
	else		
		echo "Invalid value! Please enter \"spice\" or keep default."
		chooseQueryMode
		return
	fi

}

getQSUserARN(){
	# Because identity region are different for users, and no api to get identity region, we need to consider all supported regions
	IDENTITYREGIONLIST=($REGIONCUR $CURRENTREGION us-east-1 us-east-2 us-west-2 eu-central-1 eu-west-1 eu-west-2 ap-southeast-1 ap-northeast-1 ap-southeast-2 ap-northeast-2 ap-south-1)

	# Check the identity region in supported regions one by one
	for identityregioniterator in "${IDENTITYREGIONLIST[@]}";do
		# Get user list from checking region
		QSUSERLIST=`aws quicksight list-users --aws-account-id $AccountID --namespace default --region $identityregioniterator`
		
		# Given Null cannot be caught on Cloud 9, we get the length of query result
		QSUSERLISTLENGTH=${#QSUSERLIST}

		# If query result length lower than 1, match failed, need to check next region
		if [ "$QSUSERLISTLENGTH" -lt 1 ]; then
			echo ""
			echo Searching correct identity region ...

		# If query result lenght greater than 0, match succesfully
		else
			echo ""
			echo Identity region matched !

			# Get the user numbers in user list
			QSUSERNUMBER=`echo $QSUSERLIST | jq -r '.UserList|length'`
			break
		fi

	done

	# If the user list only has one result, set QSUSERARN as this user arn 
	if [ $QSUSERNUMBER -lt 2 ]; then
		QSUSERARN=`echo $QSUSERLIST | jq -r '.UserList[0].Arn'`

	# If the user list has multiple results, print it for selection
	else
		echo ""
		echo "*****************************************************************************"
		echo $QSUSERLIST | jq -r '.UserList[].Arn'
		echo "*****************************************************************************"
		echo ""
		read -p "Please select correct quicksight user arn from above output, then enter:" QSUSERARN
			
	fi
}

updateDataSourcePermissions(){
	# Get the data source update result
	UPDATERESULT=`aws quicksight update-data-source-permissions \
	--aws-account-id $AccountID \
	--data-source-id $DATASOURCEID \
	--grant-permissions Principal=$QSUSERARN,Actions="quicksight:DescribeDataSource","quicksight:DescribeDataSourcePermissions","quicksight:PassDataSource","quicksight:UpdateDataSource","quicksight:DeleteDataSource","quicksight:UpdateDataSourcePermissions"`

	# If update result is null, usually caused by incorrect QuickSight user arn, run getQSUserARN to get correct one and updateDataSourcePermissions again
	if [ "$UPDATERESULT" = "" ]; then
		echo ""
		echo "Update datasource permissions failed, retrying ..."
		echo ""

		getQSUserARN
		updateDataSourcePermissions

		return
	else
		echo "Update datasource permissions successfully."
	fi
}

### Main function start here

# Check jq installation
checkJQ

# Set the default region, only valid in current script session or shell
CURRENTREGION=`aws configure get region`

# If has no default region, set it as us-east-1
if [ "$CURRENTREGION" = "" ]; then
	CURRENTREGION="us-east-1"
fi

# Get the destination region to deploy this solution
selectRegion

# Set the environment variable AWS_DEFAULT_REGION value to destionation region
export AWS_DEFAULT_REGION=$REGIONCUR

# Get the running profile
stsresult=`aws sts get-caller-identity`

# Get the Account ID by running profile
AccountID=`echo $stsresult | jq -r '.Account'`

# Get the user arn by running profile
IAMARN=`echo $stsresult | jq -r '.Arn'`

# Check the current OS
UNAME=`uname`

# Define the QuickSight template, this is maintained by AWS GCR Enterprise Support team
QSTEMARN="arn:aws:quicksight:us-east-1:673437017715:template/CUR-MasterTemplate-Pub"

# Choose the query mode, default is DIRECT_QUERY
chooseQueryMode

# Get Athena database/table and query result location
getAthenaConfiguration

# Based on the CUR source region, bjs or global, we will define different name for datasource/dataset/dashboard
getCURDataSourceRegion

# We need to get the raw date format in CUR, then define ETL configuration in locagical config file in necessary
getCURDateFormat

# Generate physical configuration file
PHYSICALTEMFILE="do-not-delete-physical-tem"
cp DataSetTems/$PHYSICALTEMFILE physical-table-map.json

# Generate logical configuration file
LOGICALTEMFILE="do-not-delete-logical-tem"
cp DataSetTems/$LOGICALTEMFILE logical-table-map.json

### Run isEMR,isEDP and isSP to check CUR talbe columns, then use theses vlues to update physical&logical configuration files, prepared for dataset creation
# Check if EMR cost allocation tag enabled on this account
isEMR

# Check if EDP enabled
isEDP

# Check if Saving Plan columns exist
isSP

# Add blank line before resource creation
echo ""

# Update physical&logical config file based on isEMR/isEDP/isSP results
updateConfigurationFile

### Assemble the QuickSight user arn by running profile
# Not working on Isengard cli: IAMNAME=`aws iam get-user | jq -r '.User.UserName'`; So add TMPARN to suppot on Isengard account in v0.33
TMPARN=`echo $stsresult | jq -r '.Arn'`

# Truncate current IAM user name
IAMNAME=${TMPARN#*/}

# Assemble the QuickSight user arn
QSUSERARN=arn:aws:quicksight:us-east-1:$AccountID:user/default/$IAMNAME

# Create QuickSight DataSource  
DATASOURCEID=$CURDATASOURCEREGIONSTRING"cur-datasource-id-"$REGIONCUR
DATASOURCENAME=$CURDATASOURCEREGIONSTRING"cur-datasource-"$REGIONCUR

aws quicksight create-data-source \
--aws-account-id $AccountID \
--data-source-id $DATASOURCEID \
--name $DATASOURCENAME \
--type ATHENA \
--data-source-parameters AthenaParameters={WorkGroup=primary}

# Tracking the creation status of data source every 2 seconds
for datasourcetimer in {1..15}
do
	DATASOURCECREATIONSTATUS=`aws quicksight describe-data-source --aws-account-id $AccountID --data-source-id $DATASOURCEID | jq -r '.DataSource.Status'`

	if [[ $DATASOURCECREATIONSTATUS == "CREATION_SUCCESSFUL" ]]; then
		echo Datasource has been created successfully!		
		break

	elif [[ $DATASOURCECREATIONSTATUS == "CREATION_IN_PROGRESS" ]]; then
		echo Datasource creation in progress...

		if [[ $datasourcetimer == 15 ]]; then
			echo Datasource creation timeout, please check your network connectivity and try again.
			exit
		fi
	else
		echo ""
		echo Datasource creation failed. Please run following command to check details:
		echo aws quicksight describe-data-source --aws-account-id $AccountID --data-source-id $DATASOURCEID --region $REGIONCUR
		echo ""
		exit
	fi

	sleep 2s
done

# Authorize permissons for DataSource created just now
updateDataSourcePermissions

# Get the DataSource ARN created in previous step, prepared for DataSet creation
DATASOURCEARN=`aws quicksight describe-data-source --aws-account-id $AccountID --data-source-id $DATASOURCEID | jq -r '.DataSource.Arn'`

# Update Data-Srouce ARN to physical configuration file, prepared for DataSet creation
if [[ $UNAME == "Darwin" ]];then
	sed -i "" "s#DATASOURCEARNHOLDER#$DATASOURCEARN#" physical-table-map.json
else
	sed -i "s#DATASOURCEARNHOLDER#$DATASOURCEARN#" physical-table-map.json
fi

# Create quicksight DataSet using updated configuration file
DATASETID=$CURDATASOURCEREGIONSTRING"cur-dataset-id-"$REGIONCUR
DATASETNAME=$CURDATASOURCEREGIONSTRING"cur-dataset-"$REGIONCUR

aws quicksight create-data-set \
--aws-account-id $AccountID \
--data-set-id $DATASETID \
--name $DATASETNAME \
--physical-table-map file://physical-table-map.json \
--logical-table-map file://logical-table-map.json \
--import-mode $QUERYMODE

# Note: No need to track dataset creation progress
# Authorize permissons for Created DataSet
aws quicksight update-data-set-permissions \
--aws-account-id $AccountID \
--data-set-id $DATASETID \
--grant-permissions Principal=$QSUSERARN,Actions="quicksight:DescribeDataSet","quicksight:DescribeDataSetPermissions","quicksight:PassDataSet","quicksight:DescribeIngestion","quicksight:ListIngestions","quicksight:UpdateDataSet","quicksight:DeleteDataSet","quicksight:CreateIngestion","quicksight:CancelIngestion","quicksight:UpdateDataSetPermissions"

### Create DashBoard based on previous DataSet and existing template
# Assemble the DataSet arn
DATASETARN=arn:aws:quicksight:$REGIONCUR:$AccountID:dataset/$DATASETID

# Assemble the source-entity json string for QuickSight Dashboard
DASHSOURCENT='{"SourceTemplate":{"DataSetReferences":[{"DataSetPlaceholder":"customer_all","DataSetArn":"'$DATASETARN'"}],"Arn":"'$QSTEMARN'"}}'

# Define the dashoard ID and Name
DASHBOARDID=$CURDATASOURCEREGIONSTRING"cur-dashboard-id-"$REGIONCUR
DASHBOARDNAME=$CURDATASOURCEREGIONSTRING"cur-dashboard-"$REGIONCUR

aws quicksight create-dashboard \
--aws-account-id $AccountID \
--dashboard-id $DASHBOARDID \
--name $DASHBOARDNAME \
--source-entity $DASHSOURCENT

# Tracking the creation status of dashboard every 2 seconds
for dashboardtimer in {1..15}
do
	DASHBOARDCREATIONSTATUS=`aws quicksight describe-dashboard --aws-account-id $AccountID --dashboard-id $DASHBOARDID | jq -r '.Dashboard.Version.Status'`

	if [[ $DASHBOARDCREATIONSTATUS == "CREATION_SUCCESSFUL" ]]; then
		echo Dashboard has been created successfully!
		break

	elif [[ $DASHBOARDCREATIONSTATUS == "CREATION_IN_PROGRESS" ]]; then
		
		if [[ $dashboardtimer == 15 ]]; then
			echo Dashboard creation timeout, please check your network connectivity and try again.
			exit
		fi

		echo Dashboard creation in progress...
	else
		echo ""
		echo Dashboard creation failed. Please run following command to check details:
		echo aws quicksight describe-dashboard --aws-account-id $AccountID --dashboard-id $DASHBOARDID --region $REGIONCUR
		echo ""
		exit
	fi

	sleep 2s
done

# Authorize permissions for created DashBoard
aws quicksight update-dashboard-permissions \
--aws-account-id $AccountID \
--dashboard-id $DASHBOARDID \
--grant-permissions Principal=$QSUSERARN,Actions="quicksight:DescribeDashboard","quicksight:ListDashboardVersions","quicksight:UpdateDashboardPermissions","quicksight:QueryDashboard","quicksight:UpdateDashboard","quicksight:DeleteDashboard","quicksight:DescribeDashboardPermissions","quicksight:UpdateDashboardPublishedVersion" \
--region $REGIONCUR

echo ""
echo -e "\033[1;32mCUR virsualization solution has been deployed in $REGIONCUR successfully! You can analyze your cost from QuickSight dashboard now.\033[0m"
echo ""
