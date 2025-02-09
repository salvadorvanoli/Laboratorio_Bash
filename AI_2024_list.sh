#!/bin/bash

# Laboratorio Administración de Infraestructuras 2024
# Alumno: Salvador Vanoli

mostrar_ayuda() {
	echo "---------------------------------------------------------------------------------------------------------------------------"
	echo
	echo "La sintaxis de ejecución del comando debe ser la siguiente:"
	echo
	echo "./AI_2024_list.sh [PARÁMETRO] [RUTA]"
	echo
	echo "En [PARÁMETRO] EXISTEN LAS SIGUIENTES OPCIONES:"
	echo
	echo "COMANDO -s"
	echo "Despliega la información sobre un archivo, siendo esta su nombre, tamaño, dueño y permisos"
	echo "En [RUTA] se debe incluir una ruta relativa o absoluta obligatoriamente"
	echo
	echo "COMANDO -g"
	echo "Permite ver información sobre los tres archivos más grandes del directorio especificado."
	echo "En [RUTA] se debe incluir una ruta absoluta o relativa a un directorio. Si no se incluye, [RUTA] será el directorio actual"
	echo
	echo "COMANDO -p"
	echo "Permite ver información sobre los tres archivos más pequeños del directorio especificado."
	echo "En [RUTA] se debe incluir una ruta absoluta o relativa a un directorio. Si no se incluye, [RUTA] será el directorio actual"
	echo
	echo "COMANDO -x"
	echo "Mostrará información sólo de los archivos ejecutables del directorio especificado."
	echo "En [RUTA] se debe incluir una ruta absoluta o relativa a un directorio. Si no se incluye, [RUTA] será el directorio actual"
	echo "Puede combinarse junto a los parámetros -g o -p introducidos posterior a -x, pero no con ambos a la vez."
	echo
	echo "---------------------------------------------------------------------------------------------------------------------------"
}

caso_s() {

	#Guardo la ruta pasada por parámetro como variable local dentro de la función
	local ruta=$1

	#Reviso que la ruta especificada exista
	if [ ! -e $ruta ]; then
		echo "ERROR: la ruta especificada no existe"
		exit 1
	#Reviso que la ruta especificada pertenezca a un archivo
	elif [ ! -f $ruta ]; then
		echo "ERROR: la ruta especificada no pertenece a un archivo"
		exit 1
	fi

	#Guardo el nombre del archivo en una variable local, uso basename para prescindir de la ruta y que guarde SOLO el nombre del archivo
	local nombre=$(basename $ruta)

	#Hago (ls -lh $ruta) para obtener la información del archivo pasado por parámetro, y luego utilizo awk para obtener solo las columnas
	#con la información que me interesa y formatearlas. Esto lo guardo en la variable local info
	local info=$(ls -lh $ruta | awk '{print "Tamaño: "$5, "\nDueño: "$3, "\nPermisos: "substr($1, 2)}')

	#Hago echo -e para que los saltos de línea (\n) de la variable local info se representen correctamente
	echo "Nombre: $nombre"
	echo -e "$info";
}

#Encapsulo la lógica para revisar que una ruta pasada por parámetro exista y sea un directorio para poder usarla en las funciones -g, -p y -x
revisar_ruta_valida_dir() {

	#Guardo la ruta pasada por parámetro como variable local dentro de la función
	local ruta=$1

	#Reviso que la ruta especificada exista
	if [ ! -e $ruta ]; then
		echo "ERROR: la ruta especificada no existe"
		exit 1
	#Reviso que la ruta especificada sea un directorio
	elif [ ! -d $ruta ]; then
		echo "ERROR: la ruta especificada no pertenece a un directorio"
		exit 1
	fi
}

#Encapsulo la lógica para cargar un string con archivos grandes, para así poder  usarla en las funciones -g y -x
cargar_string_archivos_grandes() {

	#Guardo la ruta y la referencia al string pasado por parámetro como variables locales de la función
        local ruta=$2
        local -n string_referenciado=$1

        #En el string referenciado realizo el comando ls -lh con la ruta (en caso de que no se haya pasado utiliza la actual),
        #luego hace egrep de una expresión regular que toma todos los elementos que inicien con -, que van a ser siempre archivos,
        #posteriormente filtra utilizando -k5, que hace que se tome la quinta columna del ls -l (la del tamaño) y filtra en orden inverso (-r, más grandes primero)
        #después de esto, toma los datos que son de interés gracias a awk (tamaño, nombre, dueño y permisos), ya que se especifican las columnas de interés (5,9,3 y 1)
	#y el tamaño lo convierte de bits a tamaño humano gracias a la función human_size definida dentro del awk. Este revisa la cantidad de bits del tamaño y
	#dependiendo de cuantos sean le agrega la unidad correspondiente (B, K, M, G),
	#ya por último elimina el primer guión (-) de la columna de permisos para que coincida con el formato especificado en la consigna
        string_referenciado=$(ls -l $ruta | egrep '^-' | sort -k5 -r | awk '
        function human_size(size) {
        	if (size < 1024) return size "B";
        	else if (size < 1048576) return sprintf("%.1fK", size / 1024);
        	else if (size < 1073741824) return sprintf("%.1fM", size / 1048576);
        	else return sprintf("%.1fG", size / 1073741824);
        }
        {
            	#Elimina el primer carácter '-' de los permisos gracias a la función substract
            	permisos = substr($1, 2)

		#Muestra el orden y formato final de los caracteres
            	print human_size($5), $9, $3, permisos
        }')
}

caso_g() {

	#Guardo la ruta pasada por parámetro como variable local dentro de la función
	local ruta=$1

	#Llamo a la función revisar_ruta_valida_dir con la ruta pasada por parámetro para que detecte si es correcta
	revisar_ruta_valida_dir $ruta

	#Creo un string llamado datos_archivos
        local datos_archivos

        #Cargo el string con los elementos más grandes del directorio pasado por parámetro
        cargar_string_archivos_grandes datos_archivos $ruta

	#Especifico las columnas, agrego un salto de línea y pongo la información obtenida. Obtengo los primeros 4 valores (encabezados y 3 primeros elementos), y formo columnas.
	echo -e "Tamaño\tNombre\tDueño\tPermisos\n $datos_archivos" | head -n 4 | column -t
}

#Encapsulo la lógica para cargar un string con archivos pequeños, para así poder  usarla en las funciones -p y -x
cargar_string_archivos_pequeños() {

	#Guardo la ruta y la referencia al string pasado por parámetro como variables locales de la función
	local ruta=$2
	local -n string_referenciado=$1

	#En el string referenciado realizo el comando ls -lh con la ruta (en caso de que no se haya pasado utiliza la actual),
        #luego hace egrep de una expresión regular que toma todos los elementos que inicien con -, que van a ser siempre archivos,
        #posteriormente filtra utilizando -k5, que hace que se tome la quinta columna del ls -l (la del tamaño) y filtra en orden normal (más pequeños primero)
        #después de esto, toma los datos que son de interés gracias a awk (tamaño, nombre, dueño y permisos), ya que se especifican las columnas de interés (5,9,3 y 1)
        #y el tamaño lo convierte de bits a tamaño humano gracias a la función human_size definida dentro del awk. Este revisa la cantidad de bits del tamaño y
        #dependiendo de cuantos sean le agrega la unidad correspondiente (B, K, M, G),
        #ya por último elimina el primer guión (-) de la columna de permisos para que coincida con el formato especificado en la consigna
        string_referenciado=$(ls -l $ruta | egrep '^-' | sort -k5 | awk '
        function human_size(size) {
                if (size < 1024) return size "B";
                else if (size < 1048576) return sprintf("%.1fK", size / 1024);
                else if (size < 1073741824) return sprintf("%.1fM", size / 1048576);
                else return sprintf("%.1fG", size / 1073741824);
        }
        {
                #Elimina el primer carácter '-' de los permisos gracias a la función substract
                permisos = substr($1, 2)

                #Muestra el orden y formato final de los caracteres
                print human_size($5), $9, $3, permisos
        }')
}

caso_p() {

	#Guardo la ruta pasada por parámetro como variable local dentro de la función
        local ruta=$1

        #Llamo a la función revisar_ruta_valida_dir con la ruta pasada por parámetro para que detecte si es correcta
        revisar_ruta_valida_dir $ruta

        #Creo un string llamado datos_archivos
        local datos_archivos

	#Cargo el string con los elementos más pequeños del directorio pasado por parámetro
	cargar_string_archivos_pequeños datos_archivos $ruta

        #Especifico las columnas, agrego un salto de línea y pongo la información obtenida. Obtengo los primeros 4 valores (encabezados y 3 primeros elementos), y formo columnas.
        echo -e "Tamaño\tNombre\tDueño\tPermisos\n $datos_archivos" | head -n 4 | column -t
}

caso_x() {

	#Guardo la ruta y el parámetro pasados a la función como variable local dentro de la misma
	local parametro=$1
	local ruta=$2

	local datos_archivos

	case $parametro in
		"-g")
			revisar_ruta_valida_dir $ruta
			cargar_string_archivos_grandes datos_archivos $ruta
		;;
		"-p")
			revisar_ruta_valida_dir $ruta
			cargar_string_archivos_pequeños datos_archivos $ruta
		;;
		*)
			#Si el parámetro enviado no es -g ni -p, pero aún así incluyeron un segundo parámetro (en teoría una ruta), el parámetro es inválido
			if [ ! -z $2 ]; then
				echo "El parámetro colocado posterior a -x no es válido"
				exit 1
			elif [ ! -z $parametro ]; then
				#Si el parámetro pasado por comando no es ni -g ni -p, ni tampoco se pasó una ruta, se supone que parámetro es la ruta,
				#por lo que se revisa su validez
        			revisar_ruta_valida_dir $parametro
			fi

			#Guardo en datos_archivos los archivos del directorio (inician con -) con los datos de interés seleccionados gracias a awk y borro el guión de los permisos (-).
			datos_archivos=$(ls -lh $parametro | egrep '^-' | awk '{print $5, $9, $3, substr($1, 2)}')

		;;
	esac

	#Muestro los elementos, siempre y cuando sean ejecutables. El awk revisa que la cuarta columna (permisos) contenga una x (ejecutable),
	#y si la tiene imprime la línea entera, también la imprime si es la primera línea (NR == 1). Por último, muestro los resultados en columnas.
	if [[ "$parametro" == "-g" || "$parametro" == "-p" ]]; then
        	#Si el parámetro es -g o -p, entonces muestro solo los primeros 4 resultados (head -n 4)
    		echo -e "Tamaño\tNombre\tDueño\tPermisos\n $datos_archivos" | awk '{if ($4 ~ /x/ || NR == 1) print $0}' | column -t | head -n 4
	else
        	# En caso contrario, muestro todos los resultados
        	echo -e "Tamaño\tNombre\tDueño\tPermisos\n $datos_archivos" | awk '{if ($4 ~ /x/ || NR == 1) print $0}' | column -t
    	fi
}

case $1 in
	"-ayuda")
		if (( $# != 1 )); then
			echo "ERROR: el comando '-ayuda' no admite parámetros"
			exit 1
		fi
		mostrar_ayuda
	;;
	"-s")
		if (( $# != 2 )); then
			echo "ERROR: la cantidad de parámetros del comando '-s' no coincide, para más ayuda ingrese '-ayuda'"
			exit 1
		fi
		caso_s $2
	;;
	"-g")
		if (( $# < 1 || $# > 2 )); then
			echo "ERROR: la cantidad de parámetros del comando '-g' no coincide, para más ayuda ingrese '-ayuda'"
			exit 1
		fi
		caso_g $2
	;;
	"-p")
		if (( $# < 1 || $# > 2 )); then
                        echo "ERROR: la cantidad de parámetros del comando '-p' no coincide, para más ayuda ingrese '-ayuda'"
                        exit 1
                fi
		caso_p $2
	;;
	"-x")
		if (( $# < 1 || $# > 3 )); then
                        echo "ERROR: la cantidad de parámetros del comando '-x' no coincide, para más ayuda ingrese '-ayuda'"
                        exit 1
                fi
		caso_x $2 $3
	;;
	*)
		echo "Parámetros no reconocidos, ingrese '-ayuda' para más información"
		exit 1
	;;
esac

exit
