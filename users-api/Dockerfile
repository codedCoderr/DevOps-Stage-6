# users/Dockerfile
FROM openjdk:17-jre-slim-bullseye
WORKDIR /app
# Assuming the JAR file is built outside the container and named app.jar
COPY target/app.jar /app/app.jar
EXPOSE 8080
CMD ["java", "-jar", "app.jar"]