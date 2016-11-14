#!/bin/sh
# ================================================================== #
# Shell script to backup databases and directories/files via s3cmd.
# ================================================================== #
# Version: 1.0.4
# ================================================================== #
# Parts copyright (c) 2012 woxxy https://github.com/woxxy/MySQL-backup-to-Amazon-S3
# Parts copyright (c) 2015 betweenbrain https://github.com/betweenbrain/MySQL-backup-to-Amazon-S3
# Updates at: https://github.com/ivan-nginx/Backup-to-Amazon-S3
# This script is licensed under MIT license
# ================================================================== #
#source ./backup-config.sh
#source /etc/backup-config.sh
source ~/backup-config.sh

DATESTAMP=$(date +"%Y.%m.%d-")
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

echo "========================="
echo "$(date +'%Y-%b-%d [%R]')"
echo "========================="
echo "Selected period: $PERIOD."
echo

# we want at least two backups, two months, two weeks, and two days
#echo "Removing old backup (2 ${PERIOD}s ago)..."
#s3cmd del --recursive s3://${S3BUCKET}/${S3PATH}previous_${PERIOD}/
#echo "Old backup removed."

#echo "Moving the backup from past $PERIOD to another folder..."
#s3cmd mv --recursive s3://${S3BUCKET}/${S3PATH}${PERIOD}/ s3://${S3BUCKET}/${S3PATH}previous_${PERIOD}/
#echo "Past backup moved."

# List all the databases, exclude standart databases
DATABASES=`mysql -u root -p$MYSQLPASS -e "SHOW DATABASES;" | tr -d "| " | grep -v "\(Database\|information_schema\|performance_schema\|mysql\|test\)"`

# Loop the databases
for DB in $DATABASES; do

	# dump database
	echo "Starting backing up '${DB}' database..."
	${MYSQLDUMPPATH}mysqldump --quick --user=${MYSQLROOT} --password=${MYSQLPASS} ${DB} | gzip > ${TMP_PATH}${DATESTAMP}${DB}.gz
	echo "Done backing up database to '${DATESTAMP}${DB}.gz' compressed file."

	# upload all databases
	echo "Uploading '${DATESTAMP}${DB}.gz' database backup..."
	s3cmd put -f ${TMP_PATH}${DATESTAMP}${DB}.gz s3://${S3BUCKET}/${S3PATH}${PERIOD}/
	echo "Database backup '${DATESTAMP}${DB}.gz' uploaded."

	# remove databases dumps
	echo "Removing local '${DATESTAMP}${DB}.gz' file..."
	rm ${TMP_PATH}${DATESTAMP}${DB}.gz
	echo "Local file '${DATESTAMP}${DB}.gz' was removed."
	echo

done;

	# backup defined files/directories with exclude
	echo "Starting compression directories..."
	tar pzcf ${TMP_PATH}${DATESTAMP}${HOSTNAME}.tar.gz ${DIRS} ${EXCLUDE}
	echo "Done compressing directories."

	echo "Uploading the new backup..."
	s3cmd put -f ${TMP_PATH}${DATESTAMP}${HOSTNAME}.tar.gz s3://${S3BUCKET}/${S3PATH}${PERIOD}/
	echo "New backup uploaded."

	echo "Removing the cache files..."
	rm ${TMP_PATH}${DATESTAMP}${HOSTNAME}.tar.gz
	echo "Cache file removed..."

echo "All done."
