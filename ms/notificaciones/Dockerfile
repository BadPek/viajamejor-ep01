# syntax=docker/dockerfile:1

# --- Etapa 1: Build (Maven + JDK 21 Alpine) ---
FROM maven:3.9-eclipse-temurin-21-alpine AS build
WORKDIR /app

# Copiar descriptor primero para aprovechar cache de capas de Maven
COPY pom.xml ./
RUN mvn -B -q dependency:go-offline

# Copiar codigo fuente y generar artefacto ejecutable
COPY src ./src
RUN mvn -B -q package -DskipTests

# --- Etapa 2: Runtime liviano (JRE 21 Alpine + usuario no-root) ---
FROM eclipse-temurin:21-jre-alpine AS runtime
WORKDIR /app

LABEL org.opencontainers.image.title="viajamejor-notificaciones" \
      org.opencontainers.image.description="Microservicio de notificaciones con consumidor SQS - ViajaMejor"

RUN addgroup -S appgroup \
    && adduser -S -G appgroup -H -s /sbin/nologin appuser

COPY --from=build --chown=appuser:appgroup /app/target/*.jar /app/app.jar

USER appuser

EXPOSE 8080

ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -Djava.security.egd=file:/dev/./urandom"

HEALTHCHECK --interval=30s --timeout=5s --start-period=25s --retries=3 \
    CMD wget -qO- http://localhost:8080/actuator/health | grep -q '"status":"UP"' || exit 1

ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar /app/app.jar"]
