#!/bin/sh

# Updates etc at: https://github.com/woxxy/MySQL-backup-to-Amazon-S3
# Under a MIT license

# change these variables to what you need
MYSQLROOT=root
MYSQLPASS=password
S3BUCKET=bucketname
# the following line prefixes the backups with the defined directory. it must be blank or end with a /
S3PATH=mysql_backup/

# when running via cron, the PATHs MIGHT be different. If you have a custom/manual MYSQL install, you should set this manually like MYSQLDUMPPATH=/usr/local/mysql/bin/
MYSQLDUMPPATH=
#tmp path.
TMP_PATH=~/

DATESTAMP=$(date +".%m.%d.%Y")
DAY=$(date +"%d")
DAYOFWEEK=$(date +"%A")

PERIOD=${1-day}
if [ ${PERIOD} = "auto" ]; then
	if [ ${DAY} = "01" ]; then
        	PERIOD=month
	elif [ ${DAYOFWEEK} = "Sunday" ]; then
        	PERIOD=week
	else
       		PERIOD=day
	fi	
fi

echo "Selected period: $PERIOD."

# we want at least two backups, two months, two weeks, and two days
echo "Removing old backup (2 ${PERIOD}s ago)..."
s3cmd del --recursive s3://${S3BUCKET}/${S3PATH}previous_${PERIOD}/
echo "Old backup removed."

echo "Moving the backup from past $PERIOD to another folder..."
s3cmd mv --recursive s3://${S3BUCKET}/${S3PATH}${PERIOD}/ s3://${S3BUCKET}/${S3PATH}previous_${PERIOD}/
echo "Past backup moved."

# List all the databases
DATABASES=`mysql -u root -p$mysqlpass -e "SHOW DATABASES;" | tr -d "| " | grep -v "\(Database\|information_schema\|performance_schema\|mysql\|test\)"`

# Loop the databases
for DB in $DATABASES; do

    # dump database
    echo "Starting backing up the database to a file..."
    ${MYSQLDUMPPATH}mysqldump --quick --user=${MYSQLROOT} --password=${MYSQLPASS} ${DB} > ${TMP_PATH}${DB}.sql
    echo "Done backing up the database to a file."

    echo "Starting compression..."
    tar czf ${TMP_PATH}${DB}${DATESTAMP}.tar.gz ${TMP_PATH}${DB}.sql
    echo "Done compressing the backup file."

    # upload all databases
    echo "Uploading the new backup..."
    s3cmd put -f ${TMP_PATH}${DB}${DATESTAMP}.tar.gz s3://${S3BUCKET}/${S3PATH}${PERIOD}/
    echo "New backup uploaded."

    echo "Removing the cache files..."
    # remove databases dump
    rm ${TMP_PATH}${DB}.sql
    rm ${TMP_PATH}${DB}${DATESTAMP}.tar.gz
    echo "Cache file removed..."

done;

echo "All done."