FROM openjdk:17-jdk as builder

WORKDIR /app

COPY pom.xml .
COPY src /app/src

RUN ./mvnw package -DskipTests

FROM openjdk:17-jre-slim

WORKDIR /app

COPY --from=builder /app/target/*.jar /app/app.jar

EXPOSE 8080

CMD ["java", "-jar", "app.jar"]