FROM ssh-attacker:2.0.4-SL
WORKDIR /usr/src/sshstatelearner

# The SSH State Learner requires graphviz to be present for visualization
RUN apk add --no-cache graphviz

# Add dependencies to optimize caching
COPY pom.xml license_header_plain.txt ./
RUN mvn dependency:resolve dependency:resolve-plugins

# Add the state learner source code
COPY . .
RUN mvn clean install

ENTRYPOINT ["java", "-jar", "apps/SSH-State-Learner.jar"]
