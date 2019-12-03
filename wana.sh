#!/bin/sh
POSIXLY_CORRECT=yes


FILTERVALUE=""
FILTERTYPE=0
SWITCH=0
STOP=0

if [ $# -eq 0 ]; then
	echo "Pouziti: ./wana [FILTR] [PRIKAT] [LOG1 [LGO2 [...]"
	STOP=1
fi


#Tato kokotina by měla nějak projekt všechny argumenty
while [ $# -ne 0 ] && [ $STOP -ne 1 ]; do
	case "$1" in
	-a)
		FILTERVALUE=$2
		FILTERTYPE=1
		shift 2		
	;;

	-b)
		FILTERVALUE=$2
		FILTERTYPE=2
		shift 2	        
	;;

	--ip|-ip)
		FILTERVALUE=$2
		FILTERTYPE=3
		shift 2
	;;

	--uri|-uri)
		FILTERVALUE=$2
		FILTERTYPE=4
		shift 2
	;;
	list-ip)
		SWITCH=1
		shift
	;;
	
	list-hosts)
		SWITCH=2
                shift
        ;;

	list-uri)
		SWITCH=3
                shift
        ;;

	hist-ip)
		SWITCH=4
                shift
        ;;
	
	hist-load)
		SWITCH=5
		shift
	;;

	*.log.*.gz | *.log.gz) #Tohle je na gzipovaný soubory

		if [ -f "$1" ]; then
			UNZIPPED=$(gunzip  -c $1)
			#echo "$UNZIPPED"
			FILTRED=""
			
        	        #Když je nastaven nějaký filtr
        	        if [ $FILTERTYPE -ne 0 ]; then
        	                #Pokud cheme filtrovat podle ip nebo uri
        	                if [ $FILTERTYPE -eq 3 ] || [ $FILTERTYPE -eq 4 ]; then
               	                 FILTRED="$(echo "$UNZIPPED" | grep $FILTERVALUE)"
               	         else
               	                 #Pokud cheme filtrovat podle data
               	                 DATE="$(echo "$UNZIPPED" | grep -E -o "\[([^\)]+)\]" "$UNZIPPED")"
               	                 echo "$DATE"
               	         fi
       	 
                else
    	                 # Pokud není žádný filtr nastaven stejně se to uloží do proměnné FILTRED akorát nijak neupravené
       	                 FILTRED="$(echo "$UNZIPPED")"
        	fi			

                #Když je nastaven nějaký příkaz
                if [ $SWITCH -ne 0 ]; then

                 case $SWITCH in
                                1) # LIST-IP
                                        # Z profiltrovaného textu jen vypíše to co je do první mezery
                                        echo "$FILTRED" | grep -E -o "^\S*" | sort -u # TEST
                                ;;

                                2) #LIST-HOSTS
                                        #Z profiltrovaného textu vytáhne jen ip adresy
                                        #a pak je skrz příkaz host zkusí nějak zpracovat

                                        FILTRED="$(echo "$FILTRED" | grep -E -o "^\S*" | sort -u)"

                                        LINENUMBER=1
                                        for line in $FILTRED
                                        do
                                                #echo "$line"
                                                NAME="$(host "$line")"
                                                if [ "$?" -eq 0  ]; then
                                                        VAR="$(echo "$NAME" | grep -E -o "([^ ]*$)")"
                                                        VAR=${VAR%.}
                                                        echo "$VAR"
                                                else
                                                        echo "$line"
                                                fi
                                                #echo $VARIABLE | grep -P -o "(?m)(?<=\bpointer ).*$"
                                        done



                                ;;
                                3) # LIST-URI
                                        # Z profiltrovaného textu vypíše uri adresy
                                        echo "$FILTRED" | grep -E -o "(http|ftp|https):\/\/[a-zA-Z0-9./?=_-]*" | sort -u

                                ;;

				 #hist ip
                                4)
					IPS="$(echo "$FILTRED" | grep -E -o "^\S*" | sort -u)" #Najdu si vsechny ip ze souboru
					for IP in $IPS
					do	#Potom iteruju ip adresy a hledat kolikrat se vyskytuji
						# Vypsani Ip adresy a a zavorek s poctem vyskytu
						COUNT=$(echo "$FILTRED" | grep -c -E -o "$IP")
						echo -n "$IP"
						echo -n " ("
						echo -n "$COUNT"
						echo -n "): "
						
						# Vypsani hashtagu odpovidajici poctu vyskytu
						j=1
						while [ $j -le $COUNT ]; do
    							echo -n "#"
    							j=$(( j + 1 ))
						done
						echo 
					done
                                ;;
                        esac
        
		

                else # Pokud není nějaký příkaz tak se jen vypíše co zrovna je
                        echo "$FILTRED"

                fi	
		else
			echo "Soubor neexistuje"
				
		fi

		
                shift

	;;

	*.log|*.log.*) #Tohle je na normální soubory
		
		if [ -f "$1" ]; then
			FILTRED=""
		UNZIPPED=$1

		#Když je nastaven nějaký filtr
		if [ $FILTERTYPE -ne 0 ]; then
			#Pokud cheme filtrovat podle ip nebo uri
			if [ $FILTERTYPE -eq 3 ] || [ $FILTERTYPE -eq 4 ]; then
				FILTRED="$(cat $1 | grep $FILTERVALUE $1)"
			else
				#Pokud cheme filtrovat podle data #Neni ani zdaleka hotove
				DATE="$(cat $1 | grep -E -o "\[([^\)]+)\]" $1)"
				echo "$DATE"
			fi
	
		else
			# Pokud není žádný filtr nastaven stejně
			# se to uloží do proměnné FILTRED akorát nijak neupravené
			FILTRED="$(cat $1)"
		fi

		#Když je nastaven nějaký příkaz
		if [ $SWITCH -ne 0 ]; then
			
			case $SWITCH in
				1) # LIST-IP
					# Z profiltrovaného textu jen vypíše to co je do první mezery
					echo "$FILTRED" | grep -E -o "^\S*" | sort -u # TEST
				;;

				2) #LIST-HOSTS
					#Z profiltrovaného textu vytáhne jen ip adresy 
					#a pak je skrz příkaz host zkusí nějak zpracovat

					FILTRED="$(echo "$FILTRED" | grep -E -o "^\S*" | sort -u)"
			
					LINENUMBER=1
					for line in $FILTRED
					do
						#echo "$line"
					        NAME="$(host "$line")"
						if [ "$?" -eq 0  ]; then
							VAR="$(echo "$NAME" | grep -E -o "([^ ]*$)")"
							VAR=${VAR%.}
							echo "$VAR"
						else
							echo "$line"
						fi
                           			#echo $VARIABLE | grep -P -o "(?m)(?<=\bpointer ).*$"
					done 

										
	
				;;
				3) # LIST-URI
					# Z profiltrovaného textu vypíše uri adresy
					echo "$FILTRED" | grep -E -o "(http|ftp|https):\/\/[a-zA-Z0-9./?=_-]*" | sort -u

				;; #hist ip
				4)
					IPS="$(echo "$FILTRED" | grep -E -o "^\S*" | sort -u)" #Najdu si vsechny ip ze souboru
					for IP in $IPS
					do	#Potom iteruju ip adresy a hledat kolikrat se vyskytuji
						# Vypsani Ip adresy a a zavorek s poctem vyskytu
						COUNT=$(echo "$FILTRED" | grep -c -E -o "$IP")
						echo -n "$IP"
						echo -n " ("
						echo -n "$COUNT"
						echo -n "): "
						
						# Vypsani hashtagu odpovidajici poctu vyskytu
						j=1
						while [ $j -le $COUNT ]; do
    							echo -n "#"
    							j=$(( j + 1 ))
						done
						echo 
					done
				;;
			esac

		else # Pokud není nějaký příkaz tak se jen vypíše co zrovna je
			echo "$FILTRED"

		fi

                else
                        echo "Soubor neexistuje"
                fi

		
		shift
	;;
	
	*)
		echo "Spatny arguemtn nebo proste neco neslo precist asi"
	        STOP=1
	;;
	esac
	
done

