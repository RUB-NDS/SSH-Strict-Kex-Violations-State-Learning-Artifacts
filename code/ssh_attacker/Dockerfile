# A simple Dockerfile to create a maven images containing the SSH-Attacker modules.
FROM maven:3.9.9-amazoncorretto-21-alpine

WORKDIR /usr/src/sshattacker

# Adding the dependencies first allows docker to skip dependency installation using the build cache
COPY pom.xml license_header_plain.txt ./
COPY SSH-Client/pom.xml ./SSH-Client/pom.xml
COPY SSH-Core/pom.xml ./SSH-Core/pom.xml
# We can only install dependencies for SSH-Core here since the other modules depend on SSH-Core to be built
RUN mvn --projects SSH-Core dependency:resolve dependency:resolve-plugins

# Add modules of the SSH-Attacker
COPY SSH-Client ./SSH-Client/
COPY SSH-Core ./SSH-Core/

# Build 'em
RUN mvn install -DskipTests=true -Dmaven.javadoc.skip=true

ENTRYPOINT ["java", "-jar", "apps/SSH-Client.jar"]
