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

dnf install mysql-server -y &>> $log_file
VALIDATE $? "Mysql server ... installation"

systemctl enable mysqld
VALIDATE $? "Mysql server ... enable" 

systemctl start mysqld 
VALIDATE $? "Mysql server ... start" 




# 1. Try to connect WITHOUT a password (checks if it's currently empty)
mysql -u root -e "exit" &> /dev/null

if [ $? -eq 0 ]; then
    echo -e "STATUS: MySQL root password is $Y NOT set $N. Setting it now..."
    
    # Use the non-interactive way to set the password
    mysql_secure_installation --set-root-pass RoboShop@1
    VALIDATE $? "MySQL root password setup"
else
    # 2. If empty login fails, check if it's already set to RoboShop@1
    mysql -u root -p'RoboShop@1' -e "exit" &> /dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "STATUS: MySQL root password is $G ALREADY set correctly $N."
    else
        echo -e "STATUS: $R Unknown Password! $N Root password is set to something else."
        exit 1
    fi
fi


end_time=$(date +%s)
final_time=$(($end_time - $start_time))
echo "script executed at $final_time"