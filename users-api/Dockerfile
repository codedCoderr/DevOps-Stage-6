# --- Stage 1: Builder ---
FROM eclipse-temurin:8-jdk AS builder

WORKDIR /app

# Copy Maven wrapper and project files first for caching
COPY pom.xml mvnw ./
COPY .mvn .mvn
COPY src src

# Ensure Maven wrapper is executable
RUN chmod +x mvnw

# Build the project and skip tests
RUN ./mvnw clean package -DskipTests

# --- Stage 2: Runtime ---
FROM eclipse-temurin:8-jre-jammy

WORKDIR /app

# Copy the built JAR from builder
COPY --from=builder /app/target/*.jar /app/app.jar

# Expose default Spring Boot port
EXPOSE 8083

# Run the Spring Boot application
ENTRYPOINT ["java", "-jar", "app.jar"]
