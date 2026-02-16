#!/bin/shell

user=$(id -u)
logs_folder="/var/log/roboshop"
log_file="$logs_folder/$0.log"
command_type=$1
start_time=$(date +%s)
Working_dir="/home/ec2-user"
mysql_host="mysql.learndaws88s.online"

#set -e
#trap 'echo "there is an error at $LINENO, command :: $BASH_COMMAND"' ERR

R="\e[31m"
G="\e[32m"
Y="\e[33m"
B="\e[34m"
N="\e[0m"

echo -e " script execution started now ... $B $command_type $N"

sudo mkdir -p $logs_folder


if [ $user -ne 0 ]; then 
     echo -e  "You need $Y sudo access $N to install packages." | tee -a $log_file
    exit 1

fi


VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$R $2 $N ... failure " | tee -a $log_file
        exit 1
    else
        echo -e "$G $2 $N ... success" | tee -a $log_file
    fi
}



dnf install maven -y&>> $log_file
VALIDATE $? "maven installed"

id roboshop &>> $log_file
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop 
    VALIDATE $? "adding user"
else
    echo "Roboshop user already exists" &>> $log_file
fi

mkdir -p /app 


curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip
cd /app

rm -rf /app/*

unzip /tmp/shipping.zip

mvn clean package &>> $log_file
mv target/shipping-1.0.jar shipping.jar

cp $Working_dir/Roboshop/shipping.service /etc/systemd/system/shipping.service

systemctl daemon-reload

systemctl enable shipping &>> $log_file

systemctl start shipping &>> $log_file
VALIDATE $? "shipping enabled ... started"

systemctl restart shipping &>> $log_file
VALIDATE $? "shipping restart"


dnf install mysql -y 
VALIDATE $? "installing mysql"

DB_USER="root"
DB_PASS="RoboShop@1"
SCHEMA_FILE="/app/db/schema.sql"

# 1. Check if a specific database exists (e.g., 'cities')
# Replace 'cities' with the actual database name used in your schema
mysql -h $mysql_host -u$DB_USER -p$DB_PASS -e "SHOW DATABASES LIKE 'cities';" | grep -w "cities" &>> $log_file

if [ $? -ne 0 ]; then
    echo "Schema not found. Loading schema..."
    mysql -h $mysql_host -u$DB_USER -p$DB_PASS < $SCHEMA_FILE
    VALIDATE $? "Schema loading"

    mysql -h $mysql_host -u$DB_USER -p$DB_PASS < /app/db/app-user.sql
    VALIDATE $? "app-user loading"

    mysql -h $mysql_host -u$DB_USER -p$DB_PASS < /app/db/master-data.sql
    VALIDATE $? "master-data loading"
    
else
    echo -e "Schema already exists. $Y Skipping load$N."
fi

systemctl restart shipping
VALIDATE $? "shipping restart"

end_time=$(date +%s)
final_time=$(($end_time - $start_time))
echo "script executed at $final_time"