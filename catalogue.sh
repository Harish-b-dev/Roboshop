#!/bin/shell

user=$(id -u)
logs_folder="/var/log/roboshop"
log_file="$logs_folder/$0.log"
command_type=$1
start_time=$(date +%s)
Working_dir=$PWD
Mongodb_host="mongodb.learndaws88s.online"

set -e
trap 'echo "there is an error at $LINENO, command :: $BASH_COMMAND"' ERR

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


dnf module disable nodejs -y &>> $log_file
VALIDATE $? "nodejs disabled"

dnf module enable nodejs:20 -y &>> $log_file
VALIDATE $? "nodejs version 20 enabled"

dnf install nodejs -y
VALIDATE $? "nodejs installed" | tee -a $log_file

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop -y &>> $log_file

mkdir -p /app 


curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
cd $Working_dir/app

rm -rf $Working_dir/app/*

unzip /tmp/catalogue.zip

npm install -y &>> $log_file

cp catalogue.service /etc/systemd/system/catalogue.service

systemctl daemon-reload -y &>> $log_file

systemctl enable catalogue -y &>> $log_file

systemctl start catalogue -y &>> $log_file
VALIDATE $? "catalogue enabled ... started" | tee -a $log_file

cp mongo.repo /etc/yum.repos.d/mongo.repo

dnf install mongodb-mongosh -y &>> $log_file

INDEX=$(mongosh --host $Mongodb_host --quiet  --eval 'db.getMongo().getDBNames().indexOf("catalogue")')

if [ INDEX -le 0 ]; then
    mongosh --host $Mongo </app/db/master-data.js &>> $log_file

else
    echo -e "schem is already loaded ... $Y skipping $N" | tee -a $log_file

fi

systemctl reload catalogue | tee -a $log_file
VALIDATE $? "catalogue reloaded" | tee -a $log_file



end_time=$(date +%s)
final_time=$(($end_time - $start_time))
echo "script executed at $final_time"