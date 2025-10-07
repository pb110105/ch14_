# ---------- build stage ----------
FROM maven:3.8.8-openjdk-17 AS build

WORKDIR /app

# copy maven files first for caching deps
COPY pom.xml .
# nếu có folder settings.xml hoặc other maven config, copy nếu cần
# COPY .mvn/ .mvn/

RUN mvn -B dependency:go-offline

# copy source
COPY src ./src

# build war (skip tests to speed up in CI; remove -DskipTests to run tests)
RUN mvn -B package -DskipTests

# ---------- runtime stage ----------
FROM tomcat:9.0-jdk17

# Remove default webapps to avoid conflicts
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy the built WAR from build stage and deploy as ROOT.war (so app served at /)
COPY --from=build /app/target/*.war /usr/local/tomcat/webapps/ROOT.war

# Optional: copy custom Tomcat conf if you have (server.xml, context.xml)
# COPY conf/server.xml /usr/local/tomcat/conf/server.xml

# Expose port (Render will map service port)
EXPOSE 8080

# Recommended JVM options can be set via env var on Render,
# but you can set defaults here if you want:
ENV CATALINA_OPTS="-Xms256m -Xmx512m -Djava.security.egd=file:/dev/./urandom"

# If your application needs SMTP credentials or other secrets,
# set them as environment variables in Render (do NOT hardcode here):
# e.g. SMTP_USER, SMTP_PASS, SMTP_HOST, SMTP_PORT, MAIL_FROM

CMD ["catalina.sh", "run"]
