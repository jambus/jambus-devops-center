#!/bin/bash
source base.cfg

echo -e "\n Build script start to run to build the aws ec2 instance..."

instanceSecurityGroup=`aws ec2 describe-security-groups --group-names ec2-spider-securitygroup --query 'SecurityGroups[0].GroupId'`
if [ $? -ne 0 ]; then
	instanceSecurityGroup=`aws ec2 create-security-group --group-name ec2-spider-securitygroup --description "ec2-jambus security group" --query 'GroupId' | sed 's/"//g'`

	aws ec2 authorize-security-group-ingress --group-name ec2-spider-securitygroup --protocol tcp --port 22 --cidr 0.0.0.0/0
	aws ec2 authorize-security-group-ingress --group-name ec2-spider-securitygroup --protocol tcp --port 80 --cidr 0.0.0.0/0
	aws ec2 authorize-security-group-ingress --group-name ec2-spider-securitygroup --protocol tcp --port 5432 --cidr 0.0.0.0/0
	aws ec2 authorize-security-group-ingress --group-name ec2-spider-securitygroup --protocol tcp --port 443 --cidr 0.0.0.0/0

	echo "Security group created: ${green}$instanceSecurityGroup${reset}"
else
	instanceSecurityGroup=`echo $instanceSecurityGroup | sed 's/"//g'`
	echo "Security group used: ${green}$instanceSecurityGroup${reset}"
fi

#echo -e "\nParsing install script..."
#rdsInstanceAddress=`aws rds describe-db-instances --db-instance-identifier $aws_rds_name --query 'DBInstances[0].Endpoint.Address' | sed 's/"//g'`
#echo "Find available RDS instance: ${green}$rdsInstanceAddress${reset}"
#properties+=("aws_rds_address=$rdsInstanceAddress")

parseTemplateWithConfigProp install-software.template > install-software

instanceResourceId=`aws ec2 run-instances --image-id $aws_ec2_ami --count 1 --instance-type t2.micro --key-name $aws_ec2_keyname --security-group-ids $instanceSecurityGroup \
	--query 'Instances[0].InstanceId' \
	--user-data file://install-software | sed 's/"//g'` 

rm install-software

#instanceResourceId=`aws ec2 run-instances --profile $1 --image-id ami-15872773 --count 1 --instance-type t2.micro --key-name jambus2018-ec2 --security-group-ids sg-c02bdab9 \
#--query 'Instances[0].InstanceId' \
#--user-data file://install-software | sed 's/"//g'`

#echo "Grant RDB connect access for EC2 instance $instanceResourceId"
#aws ec2 authorize-security-group-ingress --group-name rds-spider-securitygroup --protocol tcp --port 5432 --source-group $instanceSecurityGroup

echo "Instance Resource ID created: ${green}$instanceResourceId${reset}"
aws ec2 create-tags --resources $instanceResourceId --tags Key=Name,Value=$aws_ec2_tagname

instancePublicDNS=`aws ec2 describe-instances --instance-ids $instanceResourceId --query 'Reservations[0].Instances[0].PublicDnsName' | sed 's/"//g'`
#aws ec2 describe-instances --filters "Name=tag:Name,Values=$aws_ec2_tagname" --query 'Reservations[0].Instances[0].PublicDnsName' | sed 's/"//g' | xargs -I {} echo "ssh -i ~/jambus2018-ec2.pem ubuntu@{}"
#aws ec2 describe-instances --instance-ids $instanceResourceId --query 'Reservations[0].Instances[0].PublicDnsName' | sed 's/"//g' | xargs -I {} echo "${green}ssh -i ~/jambus2018-ec2.pem ubuntu@{}${reset}"
echo "EC2 instance start to create. PublicDnsName is: ${green}$instancePublicDNS${reset}"
echo -e "\nUse below command to connect with SSH:"
echo "${green}ssh -i ~/jambus2018-ec2.pem ubuntu@$instancePublicDNS${reset}"
echo -e "\nUse below URL to open Pyspider console when EC2 instance ready in minutes:"
echo "${green}http://$instancePublicDNS${reset}"

#echo "Clean up temp files"
#rm install-software64

echo "Script complete!"

