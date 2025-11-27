# --- Stage 1: Builder (Using stable Eclipse Temurin JDK) ---
FROM eclipse-temurin:17-jdk-jammy as builder

WORKDIR /app

# Copy Maven files
COPY pom.xml .
COPY src /app/src

# Run Maven build command, skipping tests
RUN ./mvnw package -DskipTests

# --- Stage 2: Minimal Runtime (Using stable Eclipse Temurin JRE) ---
FROM eclipse-temurin:17-jre-jammy

WORKDIR /app

# Copy the built JAR from the builder stage
COPY --from=builder /app/target/*.jar /app/app.jar

EXPOSE 8080

# Command to run the Java application
CMD ["java", "-jar", "app.jar"]