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

# 1. Try to connect with the CORRECT password first
mysql -u root -p'RoboShop@1' -e "exit" &> /dev/null

if [ $? -eq 0 ]; then
    echo -e "STATUS: MySQL root password is ${G}ALREADY set correctly${N}."
else
    echo -e "STATUS: MySQL root password ${Y}NOT set or WRONG${N}. Attempting reset..."
    
    # 2. Try to set the password (works if current password is empty)
    mysql_secure_installation --set-root-pass RoboShop@1 &>> $log_file
    
    # 3. If the above fails, it might be using the default temp password 
    # (Common in new MySQL 8.0 installs)
    if [ $? -ne 0 ]; then
        echo -e "STATUS: Standard reset failed. Checking for temporary password..."
        TEMP_PASS=$(grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}')
        mysql --connect-expired-password -u root -p"$TEMP_PASS" \
            -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'RoboShop@1';" &>> $log_file
    fi
    
    VALIDATE $? "MySQL root password setup"

end_time=$(date +%s)
final_time=$(($end_time - $start_time))
echo "script executed at $final_time"