# ----------------------------------------------------
# Etapa 1: Compilación (Build) con Maven y Java 17
# ----------------------------------------------------
FROM maven:3.9.6-eclipse-temurin-17 AS build
WORKDIR /app

# Copiamos primero el archivo de configuración de Maven para aprovechar el caché de Docker
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copiamos el código fuente y compilamos omitiendo pruebas unitarias
COPY src ./src
RUN mvn clean package -DskipTests

# ----------------------------------------------------
# Etapa 2: Imagen final para ejecución (Runtime)
# ----------------------------------------------------
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# Copiamos el ejecutable .jar generado en la etapa de build
COPY --from=build /app/target/*.jar app.jar

# Cloud Run asigna dinámicamente un puerto en la variable $PORT (por defecto 8080)
EXPOSE 8080

# Comando para arrancar la aplicación
ENTRYPOINT ["java", "-jar", "app.jar"]