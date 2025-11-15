FROM eclipse-temurin:17-jdk-alpine
WORKDIR /app
COPY target/spring_app_sak-0.0.1-SNAPSHOT.jar app.jar
EXPOSE 8088
ENV SPRING_DATASOURCE_URL=jdbc:mysql://mysql-container:3306/myapplication?createDatabaseIfNotExist=true
ENV SPRING_DATASOURCE_USERNAME=root
ENV SPRING_DATASOURCE_PASSWORD=1234
ENV SERVER_PORT=8088
ENTRYPOINT ["java", "-jar", "app.jar"]