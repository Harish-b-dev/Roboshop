#!/bin/shell

user=$(id -u)
logs_folder="/var/log/roboshop"
log_file="$logs_folder/$0.log"
command_type=$1
start_time=$(date +%s)
Working_dir="/home/ec2-user"

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

dnf install golang -y &>> $log_file
VALIDATE $? "golang installation"

id roboshop &>> $log_file
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop 
    VALIDATE $? "adding user" &>> $log_file
else
    echo "Roboshop user already exists"
fi

mkdir -p /app 


curl -L -o /tmp/dispatch.zip https://roboshop-artifacts.s3.amazonaws.com/dispatch-v3.zip &>> $log_file
cd /app

rm -rf /app/*

unzip /tmp/dispatch.zip &>> $log_file

cd /app 
go mod init dispatch &>> $log_file
go get &>> $log_file
go build &>> $log_file

cp $Working_dir/Roboshop/dispatch.service /etc/systemd/system/dispatch.service

systemctl daemon-reload

systemctl enable dispatch &>> $log_file

systemctl start dispatch &>> $log_file
VALIDATE $? "diapatch enabled ... started"

systemctl restart dispatch &>> $log_file
VALIDATE $? "dispatch restart"



end_time=$(date +%s)
final_time=$(($end_time - $start_time))
echo "script executed at $final_time"