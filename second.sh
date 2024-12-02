#!/usr/bin/bash
#Auto log extractor
#Bonch 2024
#IvanovIKudryavtsev
conf_date=1
conf_time=1
conf_time_zone=1
conf_pid=1
conf_user=1
conf_type=1
conf_data=1
conf_source="psql"
log_file_path="/var/log/postgresql/filtered.txt"
conf_counter=0
#sudo su
#echo "###$(wc -l < $log_file_path)###"
total=$(wc -l < $log_file_path)

# Функция для отображения прогресс-бара
progress_bar() {
    local progress=$1
    local done=$((progress * 50 / total))
    local left=$((50 - done))
    local fill=$(printf "%${done}s")
    local empty=$(printf "%${left}s")
    printf "\r[%s%s] %d%%" "${fill// /#}" "${empty// /-}" "$((progress * 100 / total))"
}

while read y
	do
	read -r conf <<< "$y"
	((conf_counter+=1))
	echo -e "$conf_counter" #| fold -s
	if [ $conf_counter = 1 ]; then
	conf_date="${conf: -1}"
	elif [ $conf_counter = 2 ]; then
	conf_time="${conf: -1}"
	elif [ $conf_counter = 3 ]; then
	conf_time_zone="${conf: -1}"
	elif [ $conf_counter = 4 ]; then
	conf_pid="${conf: -1}"
	elif [ $conf_counter = 5 ]; then
	conf_user="${conf: -1}"
	elif [ $conf_counter = 6 ]; then
	conf_type="${conf: -1}"
	elif [ $conf_counter = 7 ]; then
	conf_data="${conf: -1}"
	elif [ $conf_counter = 8 ]; then
	conf_source="${conf: -1}"
	else
	echo "Unbelivable"
	fi
done < /home/kali/Desktop/config.txt

DB_NAME="logging"   # Замените на ваше имя базы данных
DB_USER="postgres"
TABLE_NAME="log_top"
TABLE_EXISTS=$(psql -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT EXISTS (SELECT FROM pg_tables WHERE tablename = '$TABLE_NAME');")
# Если таблица не существует, создаем её
if [ "$TABLE_EXISTS" != "t" ]; then
  echo "Таблица не существует, создаем таблицу '$TABLE_NAME'"
  psql -U "$DB_USER" -d "$DB_NAME" -c "CREATE TABLE $TABLE_NAME (id SERIAL PRIMARY KEY,pid VARCHAR(50),usr VARCHAR(50),pr VARCHAR(50),ni VARCHAR(50),virt VARCHAR(50),res VARCHAR(50),shr VARCHAR, s VARCHAR, cpu VARCHAR, mem VARCHAR, time VARCHAR, command VARCHAR);"
else
  echo "Таблица '$TABLE_NAME' уже существует, Table deleted"
  psql -U "$DB_USER" -d "$DB_NAME" -c "DELETE FROM $TABLE_NAME; ALTER SEQUENCE log_top_id_seq RESTART WITH 1;"
fi

i=1
debug_flag=0
echo " $conf_date $conf_time $conf_time_zone $conf_pid $conf_user $conf_type $conf_data"
if [ $debug_flag = 0 ]; then
	cat $log_file_path| while read y
		do
		corrupted_event_flag=0
		read -r pid user pr ni virt res shr s cpu mem time command <<< "$y"
		if [ $corrupted_event_flag = 0 ]; then
			if ! [[ $user =~  ^.+@.+$  ]] && [ $conf_source = "psql" ]; then
			event_data="${event_type} ${event_data}"
			event_type=$user
			user=' '
			fi
			#echo -e " 1: $date \n 2: $time \n 3: $time_zone \n 4: $pid \n 5: $user \n 6: $event_type \n 7: $event_data" #| fold -s
			#echo "$s $pid"
			if [[ $s =~ ^[A-Z]$ ]] && [[ $pid =~ ^[0-9]+$ ]] && [[ $virt =~ ^[0-9]+$ ]]; then
			psql -U "$DB_USER" -d "$DB_NAME" -c "INSERT INTO $TABLE_NAME ( pid, usr, pr, ni, virt, res, shr, s, cpu, mem, time, command) VALUES ('$pid', '$user', '$pr', '$ni', '$virt', '$res', '$shr', '$s', '$cpu', '$mem', '$time', '$command');"> /dev/null 2>&1
			fi
		corrupted_event_flag=0
		fi	
		#echo "_________________________"$i"________________________"
		progress_bar $i 
		((i+=1))
	done
echo -e " "
fi
