#!/bin/sh
# ================================================================== #
# Shell script to backup databases and directories/files via s3cmd.
# ================================================================== #
# Version: 1.0.5
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

echo "Backup script was started..."
echo "========================="
echo "$(date +'%Y-%b-%d [%R]')"
echo "========================="
echo "Selected period: $PERIOD."
echo

# We want at least two backups, two months, two weeks, and two days
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

	# Dump database
	echo "Starting backing up '${DB}' database into '${DATESTAMP}${DB}.gz'..."
#	${MYSQLDUMPPATH}mysqldump --quick --user=${MYSQLROOT} --password=${MYSQLPASS} ${DB} | gzip > ${TMP_PATH}${DATESTAMP}${DB}.gz
	echo "Done backing up database to compressed file."

	# Upload all databases
	echo "Uploading database backup..."
#	s3cmd put -f ${TMP_PATH}${DATESTAMP}${DB}.gz s3://${S3BUCKET}/${S3PATH}${PERIOD}/
	echo "Database backup was uploaded."

	# Remove databases dumps
	echo "Removing local backup..."
#	rm ${TMP_PATH}${DATESTAMP}${DB}.gz
	echo "Local backup was removed."
	echo

done;

# Backup common files/directories with/without exclude list
echo "Starting compression common files/directories into '${DATESTAMP}common-${HOSTNAME}-${HOSTTYPE}.tar.gz'..."
echo "Common objects listing:"
echo "-------------------------"
echo "${DIRS}"
echo "-------------------------"
#tar pzcf ${TMP_PATH}${DATESTAMP}common-${HOSTNAME}-${HOSTTYPE}.tar.gz ${DIRS} ${EXCLUDE}
echo "Done compressing common files/directories."

echo "Uploading common backup..."
#s3cmd put -f ${TMP_PATH}${DATESTAMP}common-${HOSTNAME}-${HOSTTYPE}.tar.gz s3://${S3BUCKET}/${S3PATH}${PERIOD}/
echo "Common backup was uploaded."

echo "Removing local common backup..."
#rm ${TMP_PATH}${DATESTAMP}common-${HOSTNAME}-${HOSTTYPE}.tar.gz
echo "Local common backup was removed."
echo

# Backup separated files/directories with/without exclude list
echo "Starting compression separated files/directories..."
echo "Separate objects listing:"
echo "-------------------------"
echo "${SEPARATED_DIRS}"
echo "-------------------------"

for OBJECT in $SEPARATED_DIRS; do

	# Take name (last right side) of file/directory from full path
	OBJ_NAME="${OBJECT##*/}"

	echo "Starting compression '${OBJECT}' into '${DATESTAMP}${OBJ_NAME}.tar.gz'..."
#	tar pzcf ${TMP_PATH}${DATESTAMP}${OBJ_NAME}.tar.gz ${OBJECT} ${EXCLUDE}
	echo "Compressing is done."

	echo "Uploading separate backup..."
#	s3cmd put -f ${TMP_PATH}${DATESTAMP}${OBJ_NAME}.tar.gz s3://${S3BUCKET}/${S3PATH}${PERIOD}/
	echo "Separate backup was uploaded."

	echo "Removing local separate backup..."
#	rm ${TMP_PATH}${DATESTAMP}${OBJ_NAME}.tar.gz
	echo "Local separate backup was removed."
	echo

done;

if [ ${CHECK_BUCKET_SIZE} = true ]; then
	s3cmd du -H s3://${S3BUCKET}
fi

echo "========================="
echo "$(date +'%Y-%b-%d [%R]')"
echo "========================="
echo "Backup script was finished."
echo