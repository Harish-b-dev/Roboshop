#!/bin/shell

user=$(id -u)
logs_folder="/var/log/roboshop"
log_file="$logs_folder/$0.log"
command_type=$1
start_time=$(date +%s)

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


cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "mongodb repo updated"

dnf install mongodb-org -y 
VALIDATE $? "Installing ... mongodb" &>> $log_file

systemctl enable mongod &>> $log_file
VALIDATE $? "enabled ... mongodb"

systemctl start mongod &>> $log_file
VALIDATE $? "started ... mongodb"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf

systemctl restart mongod &>> $log_file
VALIDATE $? "started ... mongodb"

end_time=$(date +%s)
final_time=$(($end_time - $start_time))
echo "script executed at $final_time"