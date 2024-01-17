#!/bin/bash

# Function to check the operating system
get_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macOS"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "Linux"
    else
        echo "Unsupported OS"
        exit 1
    fi
}


# Función para validar la URL
validar_url() {
    if [[ $1 =~ ^http(s)?://.+ ]]; then
        return 0
    else
        return 1
    fi
}

# Función para verificar si un archivo existe
verificar_archivo() {
    if [ ! -f $1 ]; then
        echo "Error: El archivo $1 no existe."
        exit 1
    fi
}

# Función para verificar si un directorio existe
verificar_directorio() {
    if [ ! -d $1 ]; then
        echo "Error: El directorio $1 no existe."
        exit 1
    fi
}

# Pregunta las ubicaciones de los directorios si no existen
if [ ! -d "./uniadaptiveLTI-Back" ]; then
    read -p "Introduce la ubicación del directorio uniadaptiveLTI-Back (puedes obtenerlo clonando el repositorio): " BACK_DIR
else
    BACK_DIR="./uniadaptiveLTI-Back"
fi

if [ ! -d "./uniadaptiveLTI-Front" ]; then
    read -p "Introduce la ubicación del directorio uniadaptiveLTI-Front (puedes obtenerlo clonando el repositorio): " FRONT_DIR
else
    FRONT_DIR="./uniadaptiveLTI-Front"
fi

# Direcciones de los archivos
CONFIG_FILE="$BACK_DIR/config/multiple_lms_config.php"
BACK_ENV="$BACK_DIR/.env"
FRONT_ENV="$FRONT_DIR/.env"

# Pregunta si está en modo desarrollador y si quiere archivos DEV
read -p "¿Quieres activar información extra de desarrollo en la interfaz del front end? (s/N): " DEV_MODE
read -p "¿Quieres archivos DEV en el front end para desconectarlo del backend (Se ignorará el back end en la configuración)? (s/N): " DEV_FILES
if [ "$DEV_MODE" = "s" ] || [ "$DEV_MODE" = "S" ]; then
    echo "Información extra activada."
    DEV_MODE=true
else
    DEV_MODE=false
fi
if [ "$DEV_FILES" = "s" ] || [ "$DEV_MODE" = "S" ]; then
    echo "Desconectando del back end."
    DEV_FILES=true
else
    DEV_FILES=false
fi

# Pregunta las URLs del front y back
while true; do
    read -p "Introduce la URL COMPLETA del Front End (REQUIERE 'PREFIJO HTTP(S)://'): " FRONT_URL
    if validar_url $FRONT_URL; then
        break
    else
        echo "URL no válida. Inténtalo de nuevo."
    fi
done

if [ "$DEV_FILES" = "false" ]; then
    read -p "Introduce la URL del Back End (SIN PREFIJO 'HTTP(S)://'): " BACK_URL
fi

echo "Creación de instancias:"

# Configuración de LMS
if [ "$DEV_FILES" = "false" ]; then
    # Si el archivo no existe, se crea un archivo vacío
    if [ ! -f $CONFIG_FILE ]; then
        touch $CONFIG_FILE
    fi
    echo "<?php" > $CONFIG_FILE
    echo "return [" >> $CONFIG_FILE
    echo "    'lms_data' => [" >> $CONFIG_FILE

    while true; do
        read -p "Introduce un nombre para identificar la instancia de LMS (o 'salir' para terminar): " LMS_NAME
        if [ -z "$LMS_NAME" ]; then
            # Treat empty input as equivalent to "salir"
            LMS_NAME="salir"
        fi

        if [ "$LMS_NAME" = "salir" ]; then
            echo " "
            break
        fi
        while true; do
            read -p "¿Es 'sakai' o 'moodle'? " LMS_TYPE
            if [ "$LMS_TYPE" = "moodle" ]; then
                while true; do
                    read -p "Introduce la URL COMPLETA de Moodle: " MOODLE_URL
                    if validar_url $MOODLE_URL; then
                        break
                    else
                        echo "URL no válida. Inténtalo de nuevo."
                    fi
                done
                read -p "Introduce el token de Moodle: " MOODLE_TOKEN
                echo "        '$LMS_NAME' => [" >> $CONFIG_FILE
                echo "            'url' => '$MOODLE_URL'," >> $CONFIG_FILE
                echo "            'token' => '$MOODLE_TOKEN'," >> $CONFIG_FILE
                echo "        ]," >> $CONFIG_FILE
                break
            elif [ "$LMS_TYPE" = "sakai" ]; then
                while true; do
                    read -p "Introduce la URL COMPLETA de Sakai: " SAKAI_URL
                    if validar_url $SAKAI_URL; then
                        break
                    else
                        echo "URL no válida. Inténtalo de nuevo."
                    fi
                done
                read -p "Introduce el usuario de Sakai: " SAKAI_USER
                read -p "Introduce la contraseña de Sakai: " SAKAI_PASSWORD
                echo "        '$LMS_NAME' => [" >> $CONFIG_FILE
                echo "            'url' => '$SAKAI_URL'," >> $CONFIG_FILE
                echo "            'user' => '$SAKAI_USER'," >> $CONFIG_FILE
                echo "            'password' => '$SAKAI_PASSWORD'," >> $CONFIG_FILE
                echo "        ]," >> $CONFIG_FILE
                break
            else
                echo "Tipo de LMS no válido. Inténtalo de nuevo."
            fi
        done
    done

    echo "    ]," >> $CONFIG_FILE
    echo "];" >> $CONFIG_FILE
fi

# Configura /uniadaptive-Front/.env
echo "NEXT_PUBLIC_DEV_MODE=$DEV_MODE" > $FRONT_ENV
echo "NEXT_PUBLIC_DEV_FILES=$DEV_FILES" >> $FRONT_ENV
echo "NEXT_PUBLIC_BACK_URL=$BACK_URL" >> $FRONT_ENV


if [ "$DEV_FILES" = "false" ]; then
    # Configura /uniadaptive-Back/.env si no se usan archivos DEV
    verificar_archivo $BACK_DIR/.env.example
    cp $BACK_DIR/.env.example $BACK_ENV
    read -p "Introduce la contraseña de administrador para el front end (por defecto: admin): " ADMIN_PASSWORD
    ADMIN_PASSWORD=${ADMIN_PASSWORD:-admin}
    read -p "Introduce el host de la base de datos (por defecto: db (Docker, utilizar una dirección IP si no se utiliza docker)): " DB_HOST
    DB_HOST=${DB_HOST:-db}
    read -p "Introduce el puerto de la base de datos (por defecto: 3306): " DB_PORT
    DB_PORT=${DB_PORT:-3306}
    read -p "Introduce el nombre de la base de datos (por defecto: uniadaptive_back): " DB_DATABASE
    DB_DATABASE=${DB_DATABASE:-uniadaptive_back}
    read -p "Introduce el nombre de usuario de la base de datos (por defecto: root): " DB_USERNAME
    DB_USERNAME=${DB_USERNAME:-root}
    read -p "Introduce la contraseña de la base de datos (por defecto: vacío): " DB_PASSWORD
    DB_PASSWORD=${DB_PASSWORD:-""}
    

    sed -i -e "s#^FRONT_URL=.*#FRONT_URL=$FRONT_URL#g" $BACK_ENV
    sed -i -e "s#ADMIN_PASSWORD=#ADMIN_PASSWORD=$ADMIN_PASSWORD#g" "$BACK_ENV"
    sed -i -e "s#DB_HOST=#DB_HOST=$DB_HOST#g" "$BACK_ENV"
    sed -i -e "s#DB_PORT=#DB_PORT=$DB_PORT#g" "$BACK_ENV"
    sed -i -e "s#DB_DATABASE=#DB_DATABASE=$DB_DATABASE#g" "$BACK_ENV"
    sed -i -e "s#DB_USERNAME=#DB_USERNAME=$DB_USERNAME#g" "$BACK_ENV"
    sed -i -e "s#DB_PASSWORD=#DB_PASSWORD=$DB_PASSWORD#g" "$BACK_ENV"


    # Generación de claves PEM

    # Comprueba si el directorio storage existe
    if [ ! -d "$BACK_DIR/storage" ]; then
        mkdir "$BACK_DIR/storage"
    fi

    # Comprueba si el directorio storage/keys existe
    if [ ! -d "$BACK_DIR/storage/keys" ]; then
        mkdir "$BACK_DIR/storage/keys"
    fi

    echo "Generando claves..."
    openssl genrsa -out $BACK_DIR/storage/keys/private.pem 3072
    openssl rsa -in $BACK_DIR/storage/keys/private.pem -pubout -out $BACK_DIR/storage/keys/public.pem

    echo "Marcando .sh como ejecutables..."
    chmod +x $BACK_DIR/LTIPlatformCreation.sh
    chmod +x $BACK_DIR/wait-for-it.sh
fi

echo "¡Configuración completada!"

echo "Ahora deberá configurar su(s) LMS, construir el proyecto y subirlo a un servidor web."
echo "Recuerda que tendrás que editar el archivo $BACK_DIR/LTIPlatformCreation.sh con tus plataformas soportadas, y si no estás usando docker, ejecutarlo."
