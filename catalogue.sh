#!/bin/shell

user=$(id -u)
logs_folder="/var/log/roboshop"
log_file="$logs_folder/$0.log"
command_type=$1
start_time=$(date +%s)
Working_dir="/home/ec2-user"
Mongodb_host="mongodb.learndaws88s.online"

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


dnf module disable nodejs -y &>> $log_file
VALIDATE $? "nodejs disabled"

dnf module enable nodejs:20 -y &>> $log_file
VALIDATE $? "nodejs version 20 enabled"

dnf install nodejs -y&>> $log_file
VALIDATE $? "nodejs installed"

id roboshop &>> $log_file
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop 
    VALIDATE $? "adding user"
else
    echo "Roboshop user already exists"
fi

mkdir -p /app 


curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>> $log_file
cd /app

rm -rf /app/*

unzip /tmp/catalogue.zip &>> $log_file

npm install &>> $log_file

cp $Working_dir/Roboshop/catalogue.service /etc/systemd/system/catalogue.service

systemctl daemon-reload

systemctl enable catalogue &>> $log_file

systemctl start catalogue &>> $log_file
VALIDATE $? "catalogue enabled ... started"

cp $Working_dir/Roboshop/mongo.repo /etc/yum.repos.d/mongo.repo

dnf install mongodb-mongosh -y &>> $log_file

INDEX=$(mongosh --host $Mongodb_host --quiet  --eval 'db.getMongo().getDBNames().indexOf("catalogue")')

if [ $INDEX -le 0 ]; then
    mongosh --host $Mongodb_host </app/db/master-data.js &>> $log_file
    validate $? "schema loading"
else
    echo -e "schem is already loaded ... $Y skipping $N" | tee -a $log_file

fi

systemctl restart catalogue &>> $log_file
VALIDATE $? "catalogue restart" | tee -a $log_file



end_time=$(date +%s)
final_time=$(($end_time - $start_time))
echo "script executed at $final_time"